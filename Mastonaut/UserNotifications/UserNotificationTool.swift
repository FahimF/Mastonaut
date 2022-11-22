//
//  UserNotificationTool.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 12.08.19.
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
import UserNotifications

class UserNotificationTool {
	static let shared = UserNotificationTool()
	
	private var postedNotificationsCount: Int = 0 {
		didSet {
			let count = postedNotificationsCount
			DispatchQueue.main.async {
				NSApp.dockTile.badgeLabel = count == 0 ? nil : "\(count)"
			}
		}
	}

	private init() {
		// Private initializer - so that you can't instantiate and should use the shared instance
	}
	
	func updateCount(count: Int = 1) {
		DispatchQueue.main.async {
			if NSApp.isActive == false {
				self.postedNotificationsCount += count
			} else {
				self.postedNotificationsCount = 0
			}
		}
	}
	
	func postNotification(title: String, subtitle: String?, message: String?, payload: NotificationPayload? = nil) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.subtitle = subtitle ?? ""
		content.body = message ?? ""
		content.payload = payload
		let uuid = UUID().uuidString
		let request = UNNotificationRequest(identifier: uuid, content: content, trigger: nil)
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				log.info("*** Error posting local notification: \(error)")
				return
			}
			self.updateCount()
		}
	}

	func postNotification(mastodonEvent notification: MastodonNotification, receiverName: String?, userAccount: UUID, detailMode: AccountPreferences.NotificationDetailMode) {
		let showDetails: Bool

		switch detailMode {
		case .always: showDetails = true
		case .never: showDetails = false
		case .whenClean: showDetails = notification.isClean
		}

		var actorName: String {
			return showDetails ? notification.authorName : "A user"
		}
		
		var contentOrSpoiler: NSAttributedString? {
			return showDetails ? notification.status?.attributedContent : notification.status?.attributedSpoiler
		}

		let title: String
		let subtitle = receiverName.map { "For \($0)" }
		var message: String?

		switch notification.type {
		case .mention:
			title = "\(actorName) mentioned you"
			message = contentOrSpoiler?.string.ellipsedPrefix(maxLength: 80)
		case .reblog:
			title = "\(actorName) boosted your post"
			message = contentOrSpoiler?.string.ellipsedPrefix(maxLength: 80)
		case .favourite:
			title = "\(actorName) favorited your post"
			message = contentOrSpoiler?.string.ellipsedPrefix(maxLength: 80)
		case .follow:
			title = "\(actorName) followed you"
			message = showDetails ? notification.account.attributedNote.string.ellipsedPrefix(maxLength: 80) : nil
		case .poll:
			title = "A poll has ended"
			message = contentOrSpoiler?.string.ellipsedPrefix(maxLength: 80)
		default:
			return
		}

		let notificationPayload: NotificationPayload

		if let status = notification.status {
			notificationPayload = NotificationPayload(accountUUID: userAccount, referenceURI: status.resolvableURI, referenceType: .status)
		} else {
			notificationPayload = NotificationPayload(accountUUID: userAccount, referenceURI: notification.account.acct, referenceType: .account)
		}
		postNotification(title: title, subtitle: subtitle, message: message, payload: notificationPayload)
	}

	func resetDockTileBadge() {
		postedNotificationsCount = 0
	}
}

private func infoToPayload(info: [AnyHashable: Any]) -> NotificationPayload? {
	guard let dict = info["mastonaut_payload"] as? [String: Any?], let accountUUID = (dict["account_UUID"] as? String).flatMap({ UUID(uuidString: $0) }), let referenceURI = dict["reference_URI"] as? String, let referenceType = (dict["reference_type"] as? String).flatMap({ NotificationPayload.Reference(rawValue: $0) }) else {
		return nil
	}
	return NotificationPayload(accountUUID: accountUUID, referenceURI: referenceURI, referenceType: referenceType)
}

extension UNMutableNotificationContent {
	var payload: NotificationPayload? {
		set(payload) {
			var dict = userInfo
			
			if let payload = payload {
				dict["mastonaut_payload"] = [
					"account_UUID": payload.accountUUID.uuidString,
					"reference_URI": payload.referenceURI,
					"reference_type": payload.referenceType.rawValue,
				]
			} else {
				dict["mastonaut_payload"] = nil
			}
			userInfo = dict
		}
		
		get {
			return infoToPayload(info: userInfo)
		}
	}
}

extension UNNotification {
	var payload: NotificationPayload? {
		get {
			return infoToPayload(info: request.content.userInfo)
		}
	}
}

struct NotificationPayload {
	let accountUUID: UUID
	let referenceURI: String
	let referenceType: Reference

	enum Reference: String {
		case account
		case status
	}
}
