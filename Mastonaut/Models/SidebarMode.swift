//
//  SidebarMode.swift
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

enum SidebarMode: RawRepresentable, SidebarModel, Equatable {
	typealias RawValue = String

	case profile(uri: String, account: Account?)
	case tag(String)
	case status(uri: String, status: Status?)
	case favorites
	case edits(status: Status?, edits: [StatusEdit]?)

	var rawValue: String {
		switch self {
		case let .profile(uri, _):
			return "profile\n\(uri)"

		case let .tag(tagName):
			return "tag\n\(tagName)"

		case let .status(tagName, _):
			return "status\n\(tagName)"

		case .favorites:
			return "favorites"
			
		case .edits(let status, _):
			return "edits\n\(status?.id ?? "")"
		}
	}

	static func profile(uri: String) -> SidebarMode {
		return .profile(uri: uri, account: nil)
	}

	init?(rawValue: String) {
		let components = rawValue.split(separator: "\n")
		if components.count == 2 {
			if components.first == "profile" {
				self = .profile(uri: String(components[1]), account: nil)
			} else if components.first == "tag" {
				self = .tag(String(components[1]))
			} else if components.first == "status" {
				self = .status(uri: String(components[1]), status: nil)
			} else {
				return nil
			}
		} else if components.count == 1, components.first == "favorites" {
			self = .favorites
		} else {
			return nil
		}
	}

	func makeViewController(client: ClientType, currentAccount: AuthorizedAccount?, currentInstance: Instance) -> SidebarViewController {
		switch self {
		case .profile(let uri, nil):
			return ProfileViewController(uri: uri, currentAccount: currentAccount, client: client)

		case let .profile(_, .some(account)):
			return ProfileViewController(account: account, instance: currentInstance)

		case let .tag(tag):
			let service = currentAccount.map { TagBookmarkService(account: $0) }
			return TagViewController(tag: tag, tagBookmarkService: service)

		case .status(let uri, nil):
			return StatusThreadViewController(uri: uri, client: client)

		case let .status(_, .some(status)):
			return StatusThreadViewController(status: status)

		case .favorites:
			return FavoritesViewController()
			
		case .edits(let status, let edits):
			return EditHistoryViewController(status: status, edits: edits)
		}
	}

	static func == (lhs: SidebarMode, rhs: SidebarMode) -> Bool {
		switch (lhs, rhs) {
		case let (.profile(a1, _), .profile(a2, _)):
			return a1 == a2

		case let (.tag(tag1), .tag(tag2)):
			return tag1 == tag2

		case let (.status(s1, _), .status(s2, _)):
			return s1 == s2

		default:
			return false
		}
	}
}
