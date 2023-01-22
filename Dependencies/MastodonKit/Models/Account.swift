//
//  Account.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Account: Codable {
	public struct Source: Codable {
		/// Unformatted biography of user.
		public let note: String?
		/// Unformatted metadata fields in the user's profile, if any.
		public let fields: [VerifiableMetadataField]?
	}
	
    /// The ID of the account.
    public var id = ""
    /// The username of the account.
    public var username = ""
    /// Equals username for local users, includes @domain for remote ones.
    public var acct = ""
    /// The account's display name.
    public var displayName = ""
    /// Biography of user.
    public var note = ""
    /// URL of the user's profile page (can be remote).
	public var url = URL(string: "http://google.com")!
    /// URL to the avatar image.
    public var avatar: String?
    /// URL to the avatar static image
    public var avatarStatic: String?
    /// URL to the header image.
    public var header: String?
    /// URL to the header static image
    public var headerStatic: String?
    /// Boolean for when the account cannot be followed without waiting for approval first.
    public var locked = false
    /// The time the account was created.
    public var createdAt = Date()
    /// The number of followers for the account.
    public var followersCount = 0
    /// The number of accounts the given account is following.
    public var followingCount = 0
    /// The number of statuses the account has made.
    public var statusesCount = 0
    /// Reference to the account this user has moved to, if any.
    public var moved: Account?
    /// Metadata fields in the user's profile, if any.
    public var fields: [VerifiableMetadataField]?
    /// Whether this account is a bot.
    public var bot: Bool?
    /// Unformatted versions of some of the account fields.
    public var source: Source?
    /// An array of `Emoji`.
    public var emojis = [Emoji]()

    private enum CodingKeys: String, CodingKey {
        case id, username, acct
        case displayName = "display_name"
        case note, url, avatar
        case avatarStatic = "avatar_static"
        case header
        case headerStatic = "header_static"
        case locked
        case createdAt = "created_at"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case statusesCount = "statuses_count"
        case emojis, moved, fields, bot, source
    }

    public var avatarURL: URL? {
        return avatar.flatMap(URL.init(string:))
    }

    public var avatarStaticURL: URL? {
        return avatarStatic.flatMap(URL.init(string:))
    }

    public var headerURL: URL? {
        return header.flatMap(URL.init(string:))
    }

    public var headerStaticURL: URL? {
        return headerStatic.flatMap(URL.init(string:))
    }
	
	public init() {
		
	}
	
	required public init(from decoder: Decoder) throws {
		do {
			let values = try decoder.container(keyedBy: CodingKeys.self)
			id = try values.decode(String.self, forKey: .id)
			username = try values.decode(String.self, forKey: .username)
			acct = try values.decode(String.self, forKey: .acct)
			displayName = try values.decode(String.self, forKey: .displayName)
			note = try values.decode(String.self, forKey: .note)
			if let u = try? values.decode(URL.self, forKey: .url) {
				url = u
			}
			if let txt = try? values.decode(String.self, forKey: .avatar) {
				avatar = txt
			}
			if let txt = try? values.decode(String.self, forKey: .avatarStatic) {
				avatarStatic = txt
			}
			if let txt = try? values.decode(String.self, forKey: .header) {
				header = txt
			}
			if let txt = try? values.decode(String.self, forKey: .headerStatic) {
				headerStatic = txt
			}
			if let val = try? values.decode(Bool.self, forKey: .locked) {
				locked = val
			}
			createdAt = try values.decode(Date.self, forKey: .createdAt)
			followersCount = try values.decode(Int.self, forKey: .followersCount)
			followingCount = try values.decode(Int.self, forKey: .followingCount)
			statusesCount = try values.decode(Int.self, forKey: .statusesCount)
			if let a = try? values.decode(Account.self, forKey: .moved) {
				moved = a
			}
			if let arr = try? values.decode([VerifiableMetadataField].self, forKey: .fields) {
				fields = arr
			}
			if let val = try? values.decode(Bool.self, forKey: .bot) {
				bot = val
			}
			if let arr = try? values.decode([Emoji].self, forKey: .emojis) {
				emojis = arr
			}
			if let s = try? values.decode(Source.self, forKey: .source) {
				source = s
			}
		} catch {
			NSLog("*** Error decoding Account: \(error)")
			throw error
		}
	}
}
