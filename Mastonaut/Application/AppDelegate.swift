//
//  AppDelegate.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 26.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Cocoa
import CoreTootin
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
	@IBOutlet private var windowMenu: NSMenu!
	@IBOutlet private var accountsMenu: NSMenu!

	private lazy var keychain = Keychain()

	private(set) lazy var authController = AuthController(keychainController: keychainController, delegate: self)
	private(set) lazy var customEmojiCache = CustomEmojiCache(delegate: self)
	private(set) lazy var statusComposerWindowController = StatusComposerWindowController()
	private(set) lazy var aboutWindowController = AboutWindowController()
	private(set) lazy var attachmentWindowController = AttachmentWindowController()
	private(set) lazy var notificationAgent = UserNotificationAgent()
	private(set) lazy var accountsService = AccountsService(context: managedObjectContext, keychainController: keychain.keychainController)
	private(set) lazy var instanceService = InstanceService(urlSessionConfiguration: URLSessionConfiguration.forClients, keychainController: keychain.keychainController, accountsService: accountsService)

	private var _preferencesWindowController: PreferencesWindowController?

	var preferencesWindowController: PreferencesWindowController {
		if let controller = _preferencesWindowController {
			return controller
		} else {
			let storyboard = NSStoryboard(name: "Preferences", bundle: .main)
			let controller = storyboard.instantiateInitialController()! as! PreferencesWindowController
			_preferencesWindowController = controller
			return controller
		}
	}

	private var timelineWindowControllers: Set<TimelinesWindowController> = []

	private weak var authorizingEntity: (AnyObject & AccountAuthorizationSource)?

	private var observations = [NSKeyValueObservation]()
	private var reauthNotificationObserver: NSObjectProtocol?
	private var migrationErrorPresenter: (() -> Void)?

	@objc private(set) dynamic var appIsReady: Bool = false
	private var didUpdateAllAccounts = false {
		didSet { updateAppIsReady() }
	}

	#if DEBUG
		private var debugWindowController: DebugWindowController?
	#endif

	let clientsUrlSession: URLSession = .init(configuration: .forClients)
	let resourcesUrlSession: URLSession = .init(configuration: .forResources)

	lazy var avatarImageCache = AvatarImageCache(resourceURLSession: resourcesUrlSession)

	var keychainController: KeychainController {
		return keychain.keychainController
	}

	static var shared: AppDelegate {
		// If these force-unwrap fails, there's something terribly wrong with the application already.
		return NSApplication.shared.delegate! as! AppDelegate
	}

	override init() {
		super.init()
		migrateToSharedLocalKeychainIfNeeded()
		observations.observe(NSApp, \NSApplication.keyWindow) {
			[unowned self] _, _ in self.updateAccountsMenu()
		}
	}

	// MARK: - App Lifecycle
	func applicationDidFinishLaunching(_ notification: Notification) {
		log.logAppDetails()
		if accountsService.authorizedAccounts.isEmpty {
			authController.removeAllAuthorizationArtifacts()
		}
		// Reauth observer
		reauthNotificationObserver = NotificationCenter.default.addObserver(forName: .accountNeedsNewClientToken, object: nil, queue: .main) {[unowned self] notification in
			guard let account = (notification.object as? ReauthorizationAgent)?.account else { return }
			if NSAlert.accountNeedsAuthorizationDialog(account: account).runModal() == .alertFirstButtonReturn {
				self.showAccountsPreferences()
			}
		}
		// Make a timeline window if there is none
		if timelineWindowControllers.isEmpty {
			makeNewTimelinesWindow(forDecoder: false)
		}
		// User notification authorization
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
			if success {
				log.info("*** Authorized for user notifications")
				UNUserNotificationCenter.current().delegate = self
			} else if let error = error {
				print(error.localizedDescription)
			}
		}
		// Refresh our local cache of the authorized users info
		authController.updateAllAccountsLocalInfo()
		#if DEBUG
			windowMenu.addItem(.separator())
			windowMenu.addItem(withTitle: "Debug Info", action: #selector(showDebugInfoWindow(_:)), keyEquivalent: "")
		#endif
		if let errorPresenter = migrationErrorPresenter {
			migrationErrorPresenter = nil
			errorPresenter()
		}
	}

	func applicationWillBecomeActive(_: Foundation.Notification) {
		notificationAgent.notificationTool.resetDockTileBadge()
	}

	func applicationWillTerminate(_: Foundation.Notification) {
		// Ensure any pending writes finish before quitting the app.
		customEmojiCache.prepareForTermination()
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
		if !hasVisibleWindows {
			if let w = sender.windows.first {
				w.makeKeyAndOrderFront(self)
			}
//			makeNewTimelinesWindow(forDecoder: false)
		}
		return true
	}

	// MARK: - User Notifications Delegate
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let action = response.actionIdentifier
		switch action {
		case UNNotificationDismissActionIdentifier:
			// Notification was dismissed by user
			break
			
		case UNNotificationDefaultActionIdentifier:
			// App was opened from notification
			if let payload = response.notification.payload {
				showTimelinesWindow(for: payload)
//				NSUserNotificationCenter.default.removeDeliveredNotification(un)
			}
			
		default:
			break
		}
		completionHandler()
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		guard let payload = notification.payload else {
			completionHandler([])
			return
		}
		let uuid = payload.accountUUID
		guard let controller = findBestTimelinesWindowController(forAccount: uuid), controller.hasNotificationsColumn else {
			completionHandler([.banner])
			return
		}
//		return controller.window?.occlusionState.contains(.visible) != true
		completionHandler([])
	}
	
	private func showTimelinesWindow(for notificationPayload: NotificationPayload) {
		let uuid = notificationPayload.accountUUID
		let mode: SidebarMode

		switch notificationPayload.referenceType {
		case .account: mode = .profile(uri: notificationPayload.referenceURI)
		case .status: mode = .status(uri: notificationPayload.referenceURI, status: nil)
		}

		if let controller = findBestTimelinesWindowController(forAccount: uuid) {
			showDetailForNotification(mode, in: controller)
		} else if let account = accountsService.authorizedAccounts.first(where: { $0.uuid == uuid }), let controller = findTimelinesWindowControllerWithNoAccount() ?? makeNewTimelinesWindow(forDecoder: false) {
			controller.currentAccount = account
			showDetailForNotification(mode, in: controller)
		}
	}

	private func findBestTimelinesWindowController(forAccount uuid: UUID) -> TimelinesWindowController? {
		return timelineWindowControllers
			.filter { $0.currentAccount?.uuid == uuid && $0.hasNotificationsColumn }
			.sorted(by: { ($0.window?.orderedIndex ?? -1) > ($1.window?.orderedIndex ?? -1) })
			.first
	}

	private func findTimelinesWindowControllerWithNoAccount() -> TimelinesWindowController? {
		return timelineWindowControllers
			.filter { $0.currentAccount?.uuid == nil }
			.sorted(by: { ($0.window?.orderedIndex ?? -1) > ($1.window?.orderedIndex ?? -1) })
			.first
	}

	private func showDetailForNotification(_ mode: SidebarMode, in controller: TimelinesWindowController) {
		controller.window?.makeKeyAndOrderFront(self)
		controller.presentInSidebar(mode)
	}
	
	// MARK: - Timeline Windows Handling
	@discardableResult
	internal func makeNewTimelinesWindow(forDecoder: Bool) -> TimelinesWindowController? {
		let timelinesStoryboard = NSStoryboard(name: "Timelines", bundle: .main)

		guard let controller = timelinesStoryboard.instantiateInitialController() as? TimelinesWindowController else {
			return nil
		}
		if let windowFrame = Preferences.storedFrame(forTimelineWindowIndex: timelineWindowControllers.count) {
			controller.window?.setFrame(windowFrame, display: false)
		}
		timelineWindowControllers.insert(controller)
		if !forDecoder {
			controller.prepareAsEmptyWindow()
		}
		controller.showWindow(self)
		return controller
	}

	func detachTimelinesWindow(for controller: TimelinesWindowController) {
		timelineWindowControllers.remove(controller)
		controller.handleDetach()

		if let windowFrame = controller.window?.frame {
			Preferences.set(frame: windowFrame, forTimelineWindowIndex: timelineWindowControllers.count)
		}
	}

	// MARK: Preferences Window Handling

	func detachPreferencesWindow(for controller: PreferencesWindowController) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			if controller == self._preferencesWindowController, controller.window?.isVisible != true {
				self._preferencesWindowController = nil
			}
		}
	}

	// MARK: Internal Setup

	func updateAccountsMenu() {
		if let provider = (NSApp.keyWindow?.windowController as? AccountsMenuProvider) {
			accountsMenu.setItems(provider.accountsMenuItems)
		}
	}

	private func setupNotificationAgent() {
		notificationAgent.setUp()
	}

	// MARK: Client management

	private func storeLocalInfo(for account: Account, completion: @escaping () -> Void) {
		customEmojiCache.cacheEmojis(for: [account]) {
			_ in DispatchQueue.main.async { completion() }
		}
	}

	func removeAccount(for userUUID: UUID) -> Bool {
		guard let account = try? AuthorizedAccount.fetch(with: userUUID, context: managedObjectContext)
		else {
			return false
		}
		managedObjectContext.delete(account)
		updateAccountsMenu()
		timelineWindowControllers.forEach { windowController in
			if windowController.currentUser == userUUID {
				windowController.currentUser = nil
			}
			windowController.updateUserPopUpButton()
		}
		// Make sure new user data is persisted.
		saveContext()
		return true
	}

	func startAuthorizationRefresh(for account: AuthorizedAccount) {
		guard let authorizingEntity = NSApp.keyWindow?.windowController as? (AnyObject & AccountAuthorizationSource), let window = authorizingEntity.sourceWindow else {
			return
		}
		self.authorizingEntity = authorizingEntity
		authorizingEntity.prepareForAuthorization()
		authController.refreshAuthorization(for: account, with: window)
	}

	// MARK: - Core Data stack
	private lazy var persistence = Persistence()

	lazy var persistentContainer: NSPersistentContainer = {
		if let legacyPersistenceContents = legacyPersistentContainerContents() {
			Persistence.overwritePersistenceStorage(with: legacyPersistenceContents)
			sunsetLegacyPersistentContainerContents()
		}
		return persistence.persistentContainer
	}()

	var managedObjectContext: NSManagedObjectContext {
		return persistentContainer.viewContext
	}

	// MARK: - Legacy stack migration to shared stack
	private func legacyPersistentContainerContents() -> FileWrapper? {
		let legacyPersistenceDataURL = NSPersistentContainer.defaultDirectoryURL()
		if let contents = try? FileWrapper(url: legacyPersistenceDataURL, options: .immediate), contents.isDirectory,
		   contents.fileWrappers?.count ?? 0 > 0 {
			return contents
		}
		return nil
	}

	private func sunsetLegacyPersistentContainerContents() {
		let legacyPersaistenceURL = NSPersistentContainer.defaultDirectoryURL()
		try? FileManager.default.removeItem(at: legacyPersaistenceURL)
	}

	private func migrateToSharedLocalKeychainIfNeeded() {
		guard Preferences.didMigrateToSharedLocalKeychain == false else {
			return
		}
		let errors = accountsService.migrateAllAccountsToSharedLocalKeychain(keychainController: keychainController)
		guard errors.isEmpty == false else {
			Preferences.didMigrateToSharedLocalKeychain = true
			return
		}
		var accountURIs = [String]()
		for error in errors {
			error.account.needsAuthorization = true
			accountURIs.append(error.account.uri!)
		}

		// Schedule the error display to when applicationDidFinishLaunching is called
		migrationErrorPresenter = { [unowned self] in
			let alert = NSAlert(style: .warning, title: 🔠("error.migration.title"), message: 🔠("error.migration.message", accountURIs.joined(separator: "\n")))
			alert.addButton(withTitle: 🔠("error.migration.button.accountsettings"))
			alert.addButton(withTitle: 🔠("error.migration.button.moreinfo"))
			alert.addButton(withTitle: "Cancel")
			if alert.runModal() == .alertFirstButtonReturn {
				self.showAccountsPreferences()
			} else if alert.runModal() == .alertSecondButtonReturn {
				let message = errors.map { "\($0.account.uri!): \($0.underlyingError)" }.joined(separator: "\n\n")
				let alert = NSAlert(style: .informational, title: "Error Listing", message: message)
				alert.addButton(withTitle: "Close")
				alert.runModal()
			}
		}
	}

	private func showAccountsPreferences() {
		preferencesWindowController.showWindow(nil)
		preferencesWindowController.showAccountPreferences()
	}

	// MARK: - Core Data Saving and Undo support
	func saveContext() {
		// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
		let context = persistentContainer.viewContext

		if !context.commitEditing() {
			log.info("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
		}
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Customize this code block to include application-specific recovery steps.
				let nserror = error as NSError
				NSApplication.shared.presentError(nserror)
			}
		}
	}

	func windowWillReturnUndoManager(window _: NSWindow) -> UndoManager? {
		// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
		return persistentContainer.viewContext.undoManager
	}

	func application(_: NSApplication, open urls: [URL]) {
		for url in urls {
			if url.pathComponents.count > 3, url.pathComponents[1] == "grant", url.pathComponents[3] == "code", let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
				DispatchQueue.main.async {
					self.authController.completeAuthorization(from: url.pathComponents[2], grantCode: code)
				}
				return
			}
		}
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		// Save changes in the application's managed object context before the application terminates.
		let context = persistentContainer.viewContext
		if !context.commitEditing() {
			log.info("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
			return .terminateCancel
		}
		if !context.hasChanges {
			return .terminateNow
		}
		do {
			try context.save()
		} catch {
			let nserror = error as NSError
			// Customize this code block to include application-specific recovery steps.
			let result = sender.presentError(nserror)
			if result {
				return .terminateCancel
			}
			let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
			let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
			let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
			let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
			let alert = NSAlert()
			alert.messageText = question
			alert.informativeText = info
			alert.addButton(withTitle: quitButton)
			alert.addButton(withTitle: cancelButton)
			let answer = alert.runModal()
			if answer == .alertSecondButtonReturn {
				return .terminateCancel
			}
		}
		// If we got here, it is time to quit.
		return .terminateNow
	}

	private func updateAppIsReady() {
		let isReady = didUpdateAllAccounts && allCachesLoaded
		guard isReady != appIsReady else { return }
		appIsReady = isReady
	}
}

// MARK: - Cache Delegate
extension AppDelegate: CacheDelegate {
	var allCachesLoaded: Bool {
		return customEmojiCache.isLoaded
	}

	func cacheDidFinishLoadingFromDisk(_: Cache) {
		DispatchQueue.main.async { [weak self] in
			// Eventually, when other caches are created, all their `isLoaded` states must be true for
			// `appIsReady` to be true as well
			self?.updateAppIsReady()
		}
	}

	func cacheDidFinishWritingToDisk(_: Cache) {}
}

// MARK: - IBActions
extension AppDelegate {
	@IBAction func composeStatus(_ sender: Any?) {
		statusComposerWindowController.showWindow(sender)
		statusComposerWindowController.currentAccount = nil
		if !NSApp.isActive {
			NSApp.activate(ignoringOtherApps: true)
		}
	}

	@IBAction func newAuthorization(_: Any?) {
		guard let authorizingEntity = NSApp.keyWindow?.windowController as? (AnyObject & AccountAuthorizationSource), let window = authorizingEntity.sourceWindow else {
			return
		}
		self.authorizingEntity = authorizingEntity
		authorizingEntity.prepareForAuthorization()
		authController.newAuthorization(with: window)
	}

	@IBAction func newWindow(_: Any?) {
		makeNewTimelinesWindow(forDecoder: false)
		if !NSApp.isActive {
			NSApp.activate(ignoringOtherApps: true)
		}
	}

	@IBAction func orderFrontAboutPanel(_ sender: Any?) {
		aboutWindowController.showWindow(sender)
	}

	@IBAction func orderFrontPreferencesWindow(_ sender: Any?) {
		preferencesWindowController.showWindow(sender)
	}

	#if DEBUG
		@objc func showDebugInfoWindow(_ sender: Any?) {
			debugWindowController = DebugWindowController()
			debugWindowController?.showWindow(sender)
		}
	#endif
}

// MARK: - Auth Controller Delegate
extension AppDelegate: AuthControllerDelegate {
	func authControllerDidCancelAuthorization(_: AuthController) {
		resetAuthorizationState()
	}

	func authController(_: AuthController, didAuthorize account: Account, uuid: UUID) {
		// Make sure new user data is persisted.
		saveContext()

		storeLocalInfo(for: account) { [unowned self] in
			self.authorizingEntity?.successfullyAuthenticatedUser(with: uuid)
			self.informOpenWindowsOfNewAccountCredentials(forAccountUUID: uuid)
			self.resetAuthorizationState()
		}
	}

	func authController(_: AuthController, failedAuthorizingWithError error: AuthController.Errors) {
		DispatchQueue.main.async { [unowned self] in
			self.resetAuthorizationState()
			let alert = NSAlert(style: .warning, title: 🔠("authorization.title"), message: error.localizedDescription)
			alert.runModal()
		}
	}

	func authController(_: AuthController, didUpdate account: Account, uuid: UUID) {
		storeLocalInfo(for: account) { [unowned self] in
			self.authorizingEntity?.successfullyAuthenticatedUser(with: uuid)
			self.informOpenWindowsOfNewAccountCredentials(forAccountUUID: uuid)
			self.resetAuthorizationState()
		}
		timelineWindowControllers.forEach { $0.updateUserPopUpButton() }
		// Make sure new user data is persisted.
		saveContext()
	}

	func authControllerDidUpdateAllAccountLocalInfo(_: AuthController) {
		didUpdateAllAccounts = true
		setupNotificationAgent()
	}

	func authControllerDidUpdateAllAccountRelationships(_: AuthController) {}

	func resetAuthorizationState() {
		updateAccountsMenu()
		authorizingEntity?.finalizeAuthorization()
		authorizingEntity = nil
	}

	private func informOpenWindowsOfNewAccountCredentials(forAccountUUID uuid: UUID) {
		for windowController in timelineWindowControllers {
			if windowController.currentUser == uuid {
				// Re-setting this will cause the window to set itself up again in case it is stuck with bad credentials
				windowController.currentUser = uuid
			}
		}
	}
}


// MARK: - Protocols
protocol AccountsMenuProvider {
	var accountsMenuItems: [NSMenuItem] { get }
}

protocol AccountAuthorizationSource {
	var sourceWindow: NSWindow? { get }

	func successfullyAuthenticatedUser(with userUUID: UUID)
	func prepareForAuthorization()
	func finalizeAuthorization()
}
