//
//  StatusThreadViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 08.05.19.
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

import CoreTootin
import Foundation

class StatusThreadViewController: StatusListViewController, SidebarPresentable {
	private let statusURI: String
	private var status: Status? {
		didSet {
			guard let status = status else { return }
			_ = prepareNewEntries([status], for: .above, pagination: nil)
			fetchContextStatuses()
		}
	}

	var sidebarModelValue: SidebarModel {
		return SidebarMode.status(uri: statusURI, status: status)
	}

	var titleMode: SidebarTitleMode {
		return .title(🔠("Conversation"))
	}

	var mainResponder: NSResponder {
		return tableView
	}

	override var automaticallyInsertsExpander: Bool {
		return false
	}

	init(status: Status) {
		self.status = status
		statusURI = status.resolvableURI
		super.init()
	}

	init(uri: String, client: ClientType) {
		statusURI = uri
		super.init()
		self.client = client
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func registerCells() {
		super.registerCells()

		tableView.register(NSNib(nibNamed: "FocusedStatusTableCellView", bundle: .main),
		                   forIdentifier: CellViewIdentifier.focused)
	}

	override func cellViewIdentifier(for status: Status) -> NSUserInterfaceItemIdentifier {
		guard statusURI == status.resolvableURI else {
			return super.cellViewIdentifier(for: status)
		}

		return CellViewIdentifier.focused
	}

	override func clientDidChange(_ client: ClientType?, oldClient: ClientType?) {
		super.clientDidChange(client, oldClient: oldClient)

		if oldClient?.baseURL != client?.baseURL, oldClient?.baseURL != nil {
			// This will trigger a re-resolve of the status once a new client is active, since the Status ID changes
			// between different instances.
			status = nil
		}

		/// This dispatch is a fix for an issue where loading cells when the sidebar is animating will cause rows to not
		/// be sized properly (the cell will be taller than the row view, making the lower components not clickable)
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
			guard let self = self else { return }

			if let status = self.status {
				_ = self.prepareNewEntries([status], for: .above, pagination: nil)
				self.fetchContextStatuses()
			} else if let client = client {
				self.resolveStatus(using: client, fallbackSearch: false)
			}
		}
	}

	private func resolveStatus(using client: ClientType, fallbackSearch: Bool) {
		let uri = statusURI

		client.run(Search.search(query: uri, limit: 1, resolve: true)) {[weak self] result in
			if case let .failure(error) = result, case .badStatus(statusCode: 404) = error, !fallbackSearch {
				self?.resolveStatus(using: client, fallbackSearch: true)
			} else if case let .success(searchResults, _) = result, let status = searchResults.statuses.first {
				DispatchQueue.main.async { self?.status = status }
			} else {
				// TODO: Show not found placeholder
			}
		}
	}

	private func fetchContextStatuses() {
		guard let status = status, let client = client else { return }
		client.run(Statuses.context(id: status.id)) {[weak self] result in
			guard case let .success(context, _) = result else {
				return
			}
			DispatchQueue.main.async {
				_ = self?.prepareNewEntries(context.ancestors.sorted(by: { $0.createdAt < $1.createdAt }), for: .above, pagination: nil)
				_ = self?.prepareNewEntries(context.descendants.sorted(by: { $0.createdAt < $1.createdAt }), for: .below, pagination: nil)
			}
		}
	}

	override func menuItems(for status: Status) -> [NSMenuItem] {
		if statusURI == status.uri {
			return StatusMenuItemsController.shared.menuItems(for: status, interactionHandler: self)
		}
		return super.menuItems(for: status)
	}

	override func didDoubleClickRow(for status: Status) {
		authorizedAccountProvider?.presentInSidebar(SidebarMode.status(uri: status.resolvableURI, status: status))
	}

	override func applicableFilters() -> [UserFilter] {
		return super.applicableFilters().filter { $0.context.contains(.thread) }
	}

	private enum CellViewIdentifier {
		static let focused = NSUserInterfaceItemIdentifier("focused")
	}
}
