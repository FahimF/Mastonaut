//
//  Account.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Account: Codable {
    /// The ID of the account.
    public let id: String
    /// The username of the account.
    public let username: String
    /// Equals username for local users, includes @domain for remote ones.
    public let acct: String
    /// The account's display name.
    public let displayName: String
    /// Biography of user.
    public let note: String
    /// URL of the user's profile page (can be remote).
    public let url: URL
    /// URL to the avatar image.
    public let avatar: String?
    /// URL to the avatar static image
    public let avatarStatic: String?
    /// URL to the header image.
    public let header: String?
    /// URL to the header static image
    public let headerStatic: String?
    /// Boolean for when the account cannot be followed without waiting for approval first.
    public let locked: Bool
    /// The time the account was created.
    public let createdAt: Date
    /// The number of followers for the account.
    public let followersCount: Int
    /// The number of accounts the given account is following.
    public let followingCount: Int
    /// The number of statuses the account has made.
    public let statusesCount: Int
    /// Reference to the account this user has moved to, if any.
    public let moved: Account?
    /// Metadata fields in the user's profile, if any.
    public let fields: [VerifiableMetadataField]?
    /// Whether this account is a bot.
    public let bot: Bool?
    /// Unformatted versions of some of the account fields.
    public let source: Source?

    /// An array of `Emoji`.
    public var emojis: [Emoji] {
        return _emojis ?? []
    }

    /// Real storage of emojis.
    ///
    /// According to the [documentation](https://docs.joinmastodon.org/api/entities/#account),
    /// property emoji is added in 2.4.0, and it is non-optional. But for compibility with older version instance, we
    /// use `[Emoji]?` as storage and use `[Emoji]` as public API.
    private let _emojis: [Emoji]?

    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case acct
        case displayName = "display_name"
        case note
        case url
        case avatar
        case avatarStatic = "avatar_static"
        case header
        case headerStatic = "header_static"
        case locked
        case createdAt = "created_at"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case statusesCount = "statuses_count"
        case _emojis = "emojis"
        case moved
        case fields
        case bot
        case source
    }

    public struct Source: Codable {
        /// Unformatted biography of user.
        public let note: String?
        /// Unformatted metadata fields in the user's profile, if any.
        public let fields: [VerifiableMetadataField]?
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
}
