//
//  ColumnMode.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 14.04.19.
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

enum ColumnMode: RawRepresentable, ColumnModel, Equatable, Comparable {
	typealias RawValue = String

	case timeline, localTimeline, publicTimeline, notifications, favourites, bookmarks
	case tag(name: String)

	var rawValue: RawValue {
		switch self {
		case .timeline:
			return "timeline"
			
		case .localTimeline:
			return "localTimeline"
			
		case .publicTimeline:
			return "publicTimeline"
			
		case .notifications:
			return "notifications"
			
		case .favourites:
			return "favourites"
			
		case .bookmarks:
			return "bookmarks"
			
		case let .tag(name):
			return "tag:\(name)"
		}
	}

	var title: String {
		switch self {
		case .timeline:
			return "Home"
			
		case .localTimeline:
			return "Local Timeline"
			
		case .publicTimeline:
			return "Public Timeline"
			
		case .notifications:
			return "Notifications"
			
		case .favourites:
			return "Favourites"
			
		case .bookmarks:
			return "Bookmarks"
			
		case let .tag(name):
			return "Tag: \(name)"
		}
	}
	
	var image: NSImage? {
		var img: NSImage?
		switch self {
		case .timeline:
			img = NSImage(systemSymbolName: "house", accessibilityDescription: "Home")

		case .localTimeline:
			img = NSImage(systemSymbolName: "person.3", accessibilityDescription: "Local Timeline")

		case .publicTimeline:
			img = NSImage.CoreTootin.globe

		case .notifications:
			img = NSImage(systemSymbolName: "bell", accessibilityDescription: "Notifications")

		case .favourites:
			img = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Favourites")

		case .bookmarks:
			img = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: "Bookmarks")

		case let .tag(name):
			img = NSImage(systemSymbolName: "tag", accessibilityDescription: "Tag: \(name)")
		}
		return img
	}
	
	init?(rawValue: RawValue) {
		switch rawValue {
		case "timeline":
			self = .timeline
			
		case "localTimeline":
			self = .localTimeline
			
		case "publicTimeline":
			self = .publicTimeline
			
		case "notifications":
			self = .notifications
			
		case "favourites":
			self = .favourites
			
		case "bookmarks":
			self = .bookmarks
			
		case let rawValue where rawValue.hasPrefix("tag:"):
			let name = rawValue.suffix(from: rawValue.index(after: rawValue.range(of: "tag:")!.upperBound))
			self = .tag(name: String(name))

		default:
			NSLog("*** Could not find matching ColumnMode: \(rawValue)")
			return nil
		}
	}

	var weight: Int {
		switch self {
		case .bookmarks:
			return -6
			
		case .favourites:
			return -5
			
		case .timeline:
			return -4
			
		case .localTimeline:
			return -3
			
		case .publicTimeline:
			return -2
			
		case .notifications:
			return -1
			
		case .tag:
			return 0
		}
	}

	func makeViewController() -> ColumnViewController {
		switch self {
		case .timeline:
			return TimelineViewController(source: .timeline)
			
		case .favourites:
			return TimelineViewController(source: .favorites)
			
		case .bookmarks:
			return TimelineViewController(source: .bookmarks)
			
		case .localTimeline:
			return TimelineViewController(source: .localTimeline)
			
		case .publicTimeline:
			return TimelineViewController(source: .publicTimeline)
			
		case .notifications:
			return NotificationListViewController()
			
		case let .tag(name):
			return TimelineViewController(source: .tag(name: name))
		}
	}

	private func makeMenuItem() -> NSMenuItem {
		let menuItem = NSMenuItem()
		menuItem.representedObject = self
		menuItem.title = self.title
		menuItem.image = self.image
		return menuItem
	}

	func makeMenuItemForAdding(with target: AnyObject) -> NSMenuItem {
		let menuItem = makeMenuItem()
		menuItem.target = target
		menuItem.action = #selector(TimelinesWindowController.addColumnMode(_:))
		return menuItem
	}

	func makeMenuItemForChanging(with target: AnyObject, columnId: Int) -> NSMenuItem {
		let menuItem = makeMenuItem()
		menuItem.tag = columnId
		menuItem.target = target
		menuItem.action = #selector(TimelinesWindowController.changeColumnMode(_:))
		return menuItem
	}

	static var allItems: [ColumnMode] {
		return [.timeline, .localTimeline, .publicTimeline, .notifications, .bookmarks, .favourites]
	}

	static func == (lhs: ColumnMode, rhs: ColumnMode) -> Bool {
		switch (lhs, rhs) {
		case (.timeline, .timeline):
			return true
		case (.localTimeline, .localTimeline):
			return true
		case (.publicTimeline, .publicTimeline):
			return true
		case (.notifications, .notifications):
			return true
		case let (.tag(leftTag), .tag(righTag)):
			return leftTag == righTag
		default:
			return false
		}
	}

	static func < (lhs: ColumnMode, rhs: ColumnMode) -> Bool {
		if lhs.weight != rhs.weight {
			return lhs.weight < rhs.weight
		}

		switch (lhs, rhs) {
		case let (.tag(leftTag), .tag(rightTag)):
			return leftTag < rightTag

		default:
			return false
		}
	}
}
