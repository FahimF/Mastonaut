//
//  StatusEdit.swift
//  MastodonKit
//
//  Created by Sören Kuklau on 07.01.23.
//

import Foundation

public class StatusEdit: Codable {
    /// The content of the status at this revision, as HTML.
    public let content: String
    /// The content of the subject or content warning at this revision, as HTML.
    public let spoilerText: String
    /// Whether the status was marked sensitive at this revision.
    public let sensitive: Bool?
    /// The timestamp of when the revision was published.
    public let createdAt: Date
    /// The account that published this revision.
    public let account: Account
    /// The current state of the poll options at this revision. Note that edits changing the poll options will be collapsed together into one edit, since this action resets the poll.
    public let poll: Poll?
    public let mediaAttachments: [Attachment]
    /// Any custom emoji that are used in the current revision.
    public let emojis: [Emoji]

    private enum CodingKeys: String, CodingKey {
        case content
        case spoilerText = "spoiler_text"
        case sensitive
        case createdAt = "created_at"
        case account
        case poll
        case mediaAttachments = "media_attachments"
        case emojis
    }
}
