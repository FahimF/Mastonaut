//
//  FollowCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 26.01.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
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

import AppKit
import CoreTootin

class FollowCellView: MastonautTableCellView, NotificationDisplaying {
	@IBOutlet private unowned var interactionIcon: NSImageView!
	@IBOutlet private unowned var interactionLabel: NSButton!
	@IBOutlet private unowned var agentAvatarButton: NSButton!
	@IBOutlet private unowned var userAccountLabel: NSTextField!
	@IBOutlet private unowned var userBioLabel: AttributedLabel!
	@IBOutlet private unowned var timeLabel: NSTextField!

	private unowned var interactionHandler: NotificationInteractionHandling?

	private var agentAccount: Account?
	private var displayedNotificationTags: [Tag]?

	var displayedNotificationId: String?

	// This cell never displays statuses
	let displayedStatusId: String? = nil

	private static let followLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: MastonautPreferences.instance.normalTextSize, weight: .medium),
	]

	private static let userBioLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: MastonautPreferences.instance.normalTextSize),
		.underlineStyle: NSNumber(value: 0), // <-- This is a hack to prevent the label's contents from shifting
		// vertically when clicked.
	]

	private static let bioLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.safeControlTintColor,
		.font: NSFont.systemFont(ofSize: MastonautPreferences.instance.normalTextSize, weight: .medium),
		.underlineStyle: NSNumber(value: 1),
	]

	override func awakeFromNib() {
		super.awakeFromNib()

		timeLabel.formatter = RelativeDateFormatter.shared
		userBioLabel.linkTextAttributes = FollowCellView.bioLabelLinkAttributes
	}

	override var backgroundStyle: NSView.BackgroundStyle {
		didSet {
			let emphasized = backgroundStyle == .emphasized
			userBioLabel.isEmphasized = emphasized

			if #available(OSX 10.14, *) {} else {
				let effectiveColor: NSColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
				userAccountLabel.textColor = effectiveColor
				timeLabel.textColor = effectiveColor
			}
		}
	}

	func set(displayedNotification notification: MastodonNotification,
	         attachmentPresenter _: AttachmentPresenting,
	         interactionHandler: NotificationInteractionHandling,
	         activeInstance: Instance)
	{
		displayedNotificationId = notification.id
		self.interactionHandler = interactionHandler
		agentAccount = notification.account
		let accountEmojis = notification.account.cacheableEmojis

		displayedNotificationTags = notification.status?.tags

		userBioLabel.linkHandler = self

		interactionLabel.set(stringValue: 🔠("%@ followed you", notification.authorName),
		                     applyingAttributes: FollowCellView.followLabelAttributes,
		                     applyingEmojis: accountEmojis)

		userBioLabel.set(attributedStringValue: notification.account.attributedNote,
		                 applyingAttributes: FollowCellView.userBioLabelAttributes,
		                 applyingEmojis: accountEmojis)

		userBioLabel.isHidden = userBioLabel.attributedStringValue.length == 0
		userBioLabel.selectableAfterFirstClick = true

		userAccountLabel.stringValue = notification.account.uri(in: activeInstance)
		timeLabel.objectValue = notification.createdAt
		timeLabel.toolTip = DateFormatter.longDateFormatter.string(from: notification.createdAt)

		let localNotificationID = notification.id
		AppDelegate.shared.avatarImageCache.fetchImage(account: notification.account) { [weak self] result in
			switch result {
			case let .inCache(avatarImage):
				assert(Thread.isMainThread)
				self?.agentAvatarButton.image = avatarImage
			case let .loaded(avatarImage):
				self?.applyAgentImageIfNotReused(avatarImage, originatingNotificationID: localNotificationID)
			case .noImage:
				self?.applyAgentImageIfNotReused(nil, originatingNotificationID: localNotificationID)
			}
		}
	}

	private func applyAgentImageIfNotReused(_ image: NSImage?, originatingNotificationID: String) {
		DispatchQueue.main.async { [weak self] in
			// Make sure that the notification view hasn't been reused since this fetch was dispatched.
			guard self?.displayedNotificationId == originatingNotificationID else {
				return
			}

			self?.agentAvatarButton.image = image ?? #imageLiteral(resourceName: "missing")
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		displayedNotificationId = nil

		interactionLabel.stringValue = ""
		agentAvatarButton.image = #imageLiteral(resourceName: "missing")
		userAccountLabel.stringValue = ""
		userBioLabel.stringValue = ""
		timeLabel.stringValue = ""
	}

	@IBAction func showAccount(_: Any?) {
		agentAccount.map { interactionHandler?.show(account: $0) }
	}
}

extension FollowCellView: AttributedLabelLinkHandler {
	func handle(linkURL: URL) {
		interactionHandler?.handle(linkURL: linkURL, knownTags: displayedNotificationTags)
	}
}

extension FollowCellView: RichTextCapable {
	func set(shouldDisplayAnimatedContents animates: Bool) {
		interactionLabel.animatedEmojiImageViews?.forEach { $0.animates = animates }
		userBioLabel.animatedEmojiImageViews?.forEach { $0.animates = animates }
	}
}
