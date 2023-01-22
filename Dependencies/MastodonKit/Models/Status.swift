//
//  Status.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Status: Codable {
    /// The ID of the status.
    public var id = ""
    /// A Fediverse-unique resource ID.
    public var uri = ""
    /// URL to the status page (can be remote).
    public var url: URL?
    /// The Account which posted the status.
    public var account = Account()
    /// null or the ID of the status it replies to.
    public var inReplyToID: String?
    /// null or the ID of the account it replies to.
    public var inReplyToAccountID: String?
    /// Body of the status; this will contain HTML (remote HTML already sanitized).
    public var content = ""
    /// The time the status was created.
    public var createdAt = Date()
    /// An array of Emoji.
    public var emojis = [Emoji]()
    /// The number of reblogs for the status.
    public var reblogsCount = 0
    /// The number of favourites for the status.
    public var favouritesCount = 0
    /// Whether the authenticated user has reblogged the status.
    public var reblogged: Bool?
    /// Whether the authenticated user has favourited the status.
    public var favourited: Bool?
	/// Whether the authenticated user has bookmarked the status.
	public var bookmarked: Bool?
    /// Whether media attachments should be hidden by default.
    public var sensitive: Bool?
    /// If not empty, warning text that should be displayed before the actual content.
    public var spoilerText = ""
    /// The visibility of the status.
    public var visibility: Visibility!
    /// An array of attachments.
    public var mediaAttachments = [Attachment]()
    /// An array of mentions.
    public var mentions = [Mention]()
    /// An array of tags.
    public var tags = [Tag]()
    /// Application from which the status was posted.
    public var application: Application?
    /// The detected language for the status.
    public var language: String?
    /// The reblogged Status
    public var reblog: Status?
    /// Whether this is the pinned status for the account that posted it.
    public private(set) var pinned: Bool?
    /// A content card with linked content.
    public var card: Card?
    /// A poll
    public var poll: Poll?
	/// Timestamp of when the status was last edited.
	public var editedAt: Date?
	
	// New properties
	/// How many replies this status has received
	public let repliesCount: Int

    private enum CodingKeys: String, CodingKey {
        case id, uri, url, account, content, emojis, reblogged, favourited, bookmarked, sensitive, visibility
		case mentions, tags, application, language, reblog, pinned, card, poll
        case inReplyToID = "in_reply_to_id"
        case inReplyToAccountID = "in_reply_to_account_id"
        case createdAt = "created_at"
        case reblogsCount = "reblogs_count"
        case favouritesCount = "favourites_count"
		case spoilerText = "spoiler_text"
		case mediaAttachments = "media_attachments"
		case editedAt = "edited_at"
		case repliesCount = "replies_count"
    }

	required public init(from decoder: Decoder) throws {
		do {
			let values = try decoder.container(keyedBy: CodingKeys.self)
			id = try values.decode(String.self, forKey: .id)
			uri = try values.decode(String.self, forKey: .uri)
			if let u = try? values.decode(URL.self, forKey: .url) {
				url = u
			}
			if let a = try? values.decode(Account.self, forKey: .account) {
				account = a
			}
			if let txt = try? values.decode(String.self, forKey: .inReplyToID) {
				inReplyToID = txt
			}
			if let txt = try? values.decode(String.self, forKey: .inReplyToAccountID) {
				inReplyToAccountID = txt
			}
			content = try values.decode(String.self, forKey: .content)
			createdAt = try values.decode(Date.self, forKey: .createdAt)
			emojis = try values.decode([Emoji].self, forKey: .emojis)
			reblogsCount = try values.decode(Int.self, forKey: .reblogsCount)
			favouritesCount = try values.decode(Int.self, forKey: .favouritesCount)
			if let val = try? values.decode(Bool.self, forKey: .reblogged) {
				reblogged = val
			}
			if let val = try? values.decode(Bool.self, forKey: .favourited) {
				favourited = val
			}
			if let val = try? values.decode(Bool.self, forKey: .bookmarked) {
				bookmarked = val
			}
			if let val = try? values.decode(Bool.self, forKey: .sensitive) {
				sensitive = val
			}
			spoilerText = try values.decode(String.self, forKey: .spoilerText)
			visibility = try values.decode(Visibility.self, forKey: .visibility)
			mediaAttachments = try values.decode([Attachment].self, forKey: .mediaAttachments)
			mentions = try values.decode([Mention].self, forKey: .mentions)
			if let t = try? values.decode([Tag].self, forKey: .tags) {
				tags = t
			}
			if let app = try? values.decode(Application.self, forKey: .application) {
				application = app
			}
			if let txt = try? values.decode(String.self, forKey: .language) {
				language = txt
			}
			// Recursive loading (reblogs are Status values whicn can contain other reblog items) can result in crashes if this is not set up to check if the vlalue is present
			if let r = try? values.decodeIfPresent(Status.self, forKey: .reblog) {
				reblog = r
			}
			if let val = try? values.decode(Bool.self, forKey: .pinned) {
				pinned = val
			}
			if let c = try? values.decode(Card.self, forKey: .card) {
				card = c
			}
			if let p = try? values.decode(Poll.self, forKey: .poll) {
				poll = p
			}
			if let dt = try? values.decode(Date.self, forKey: .editedAt) {
				editedAt = dt
			}
			repliesCount = try values.decode(Int.self, forKey: .repliesCount)
//			if let arr = try? values.decode([Filtered].self, forKey: .filtered) {
//				filtered = arr
//			}
		} catch {
			NSLog("*** Error decoding Status: \(error)")
			throw error
		}
	}

    public func markAsPinned() {
        pinned = true
    }
}
