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
	internal var source: Source? {
		didSet { if source != oldValue { sourceDidChange(source: source) }}
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

		case .localTimeline:
			setClientEventStream(.publicLocal)

		case .publicTimeline:
			setClientEventStream(.public)

		case let .tag(name):
			setClientEventStream(.hashtag(name))

		case .userStatuses, .userMediaStatuses, .userStatusesAndReplies, .favorites:
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
			DispatchQueue.main.async {
				[weak self] in

				guard let self = self else { return }

				if self.entryMap[status.key] != nil {
					self.handle(updatedEntry: status)
				} else {
					self.prepareNewEntries([status], for: .above, pagination: nil)
				}
			}

		case let .delete(statusID):
			DispatchQueue.main.async { [weak self] in self?.handle(deletedEntry: statusID) }

		case .notification:
			break

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
		case .favorites: currentContext = .home
		case .localTimeline: currentContext = .public
		case .publicTimeline: currentContext = .public
		case .tag: currentContext = .home
		case .timeline: currentContext = .home
		case .userMediaStatuses: currentContext = .account
		case .userStatuses: currentContext = .account
		case .userStatusesAndReplies: currentContext = .account
		}

		return super.applicableFilters().filter { $0.context.contains(currentContext) }
	}

	enum Source: Equatable {
		case timeline
		case localTimeline
		case publicTimeline
		case favorites
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
		case .timeline: return ColumnMode.timeline
		case .localTimeline: return ColumnMode.localTimeline
		case .publicTimeline: return ColumnMode.publicTimeline
		case let .tag(name): return ColumnMode.tag(name: name)

		case .userStatuses, .userMediaStatuses, .userStatusesAndReplies, .favorites:
			return nil
		}
	}
}
