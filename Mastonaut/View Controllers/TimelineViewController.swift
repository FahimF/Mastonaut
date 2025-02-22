//
//  TimelineViewController.swift
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

class TimelineViewController: StatusListViewController {
	private let notifierTool = UserNotificationTool.shared
	
	internal var source: Source? {
		didSet {
			if source != oldValue {
				sourceDidChange(source: source)
			}
		}
	}

	init(source: Source?) {
		self.source = source
		super.init()
		updateAccessibilityAttributes()
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	internal func sourceDidChange(source _: Source?) {
		updateAccessibilityAttributes()
	}

	override func clientDidChange(_ client: ClientType?, oldClient: ClientType?) {
		super.clientDidChange(client, oldClient: oldClient)
		guard let source = source else {
			return
		}
		switch source {
		case .timeline:
			setClientEventStream(.user)

		case .favorites:
			setClientEventStream(.favourites)

		case .bookmarks:
			setClientEventStream(.bookmarks)

		case .localTimeline:
			setClientEventStream(.publicLocal)

		case .publicTimeline:
			setClientEventStream(.public)

		case let .tag(name):
			setClientEventStream(.hashtag(name))

		case .userStatuses, .userMediaStatuses, .userStatusesAndReplies:
			#if DEBUG
				DispatchQueue.main.async { self.showStatusIndicator(state: .off) }
			#endif
		}
	}

	override internal func fetchEntries(for insertion: InsertionPoint) {
		guard let source = source else {
			return
		}
		super.fetchEntries(for: insertion)
		let request: Request<[Status]>
		switch source {
		case .timeline:
			request = Timelines.home(range: rangeForEntryFetch(for: insertion))

		case .publicTimeline:
			request = Timelines.public(local: false, range: rangeForEntryFetch(for: insertion))

		case .localTimeline:
			request = Timelines.public(local: true, range: rangeForEntryFetch(for: insertion))

		case .favorites:
			let range = lastPaginationResult?.next ?? rangeForEntryFetch(for: insertion)
			request = Favourites.all(range: range)

		case .bookmarks:
			let range = lastPaginationResult?.next ?? rangeForEntryFetch(for: insertion)
			request = Bookmarks.all(range: range)

		case let .userStatuses(account):
			request = Accounts.statuses(id: account, excludeReplies: true, range: rangeForEntryFetch(for: insertion))

		case let .userStatusesAndReplies(account):
			request = Accounts.statuses(id: account, excludeReplies: false, range: rangeForEntryFetch(for: insertion))

		case let .userMediaStatuses(account):
			request = Accounts.statuses(id: account, mediaOnly: true, range: rangeForEntryFetch(for: insertion))

		case let .tag(tagName):
			request = Timelines.tag(tagName, range: rangeForEntryFetch(for: insertion))
		}
		run(request: request, for: insertion)
	}

	override func receivedClientEvent(_ event: ClientEvent) {
		switch event {
		case let .update(status):
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				if self.entryMap[status.key] != nil {
					self.handle(updatedEntry: status)
					self.updateCount(count: 1)
				} else {
					let count = self.prepareNewEntries([status], for: .above, pagination: nil)
					self.updateCount(count: count)
				}
			}

		case let .delete(statusID):
			DispatchQueue.main.async { [weak self] in
				self?.handle(deletedEntry: statusID)
			}

		case .notification:
			break

		case .unhandled:
			log.info("*** Unhandled client event received")
			
		case .keywordFiltersChanged:
			break
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		updateAccessibilityAttributes()
	}

	private func updateAccessibilityAttributes() {
		guard isViewLoaded, let source = source else {
			tableView?.setAccessibilityLabel(nil)
			return
		}
		switch source {
		case .timeline:
			tableView.setAccessibilityLabel("Home Timeline")
		case .localTimeline:
			tableView.setAccessibilityLabel("Local Timeline")
		case .publicTimeline:
			tableView.setAccessibilityLabel("Public Timeline")
		case .favorites:
			tableView.setAccessibilityLabel("Favorites Timeline")
		case .bookmarks:
			tableView.setAccessibilityLabel("Bookmarks Timeline")
		case let .tag(name):
			tableView.setAccessibilityLabel("Timeline for tag \(name)")
		default:
			break
		}
	}

	override func applicableFilters() -> [UserFilter] {
		guard let source = source else {
			return super.applicableFilters()
		}
		let currentContext: Filter.Context
		switch source {
			// Do not do any filtering for favourites and bookmarks
		case .favorites, .bookmarks:
			return []
			
		case .tag, .timeline:
			currentContext = .home
			
		case .localTimeline, .publicTimeline:
			currentContext = .public
			
		case .userMediaStatuses, .userStatuses, .userStatusesAndReplies:
			currentContext = .account
		}
		return super.applicableFilters().filter { $0.context.contains(currentContext) }
	}

	private func updateCount(count: Int) {
		// Handle updating badge count for Home
		if source == .timeline {
			notifierTool.updateCount(count: count)
		}
	}
	
	enum Source: Equatable {
		case timeline
		case localTimeline
		case publicTimeline
		case favorites
		case bookmarks
		case userStatuses(id: String)
		case userStatusesAndReplies(id: String)
		case userMediaStatuses(id: String)
		case tag(name: String)
	}
}

extension TimelineViewController: ColumnPresentable {
	var mainResponder: NSResponder {
		return tableView
	}

	var modelRepresentation: ColumnModel? {
		guard let source = source else {
			return nil
		}
		switch source {
		case .timeline:
			return ColumnMode.timeline
			
		case .localTimeline:
			return ColumnMode.localTimeline
			
		case .publicTimeline:
			return ColumnMode.publicTimeline
			
		case .favorites:
			return ColumnMode.favourites
			
		case .bookmarks:
			return ColumnMode.bookmarks
			
		case let .tag(name):
			return ColumnMode.tag(name: name)

		case .userStatuses, .userMediaStatuses, .userStatusesAndReplies:
			return nil
		}
	}
}
