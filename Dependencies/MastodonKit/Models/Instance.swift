//
//  Instance.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Instance: Codable {
    /// URI of the current instance.
    public let uri: String
    /// The instance's title.
    public let title: String
    /// A description for the instance.
    public let description: String
    /// An email address which can be used to contact the instance administrator.
    public let email: String
    /// The Mastodon version used by instance (as of version 1.3).
    public let version: String?
    /// A thumbnail image to use for this instance (as of version 1.6.1).
    public let thumbnail: URL?
    /// Some statistics about this instance (as of version 1.6).
    public let stats: InstanceStats?
    /// List of "official" languages used in this instance (as of version 2.3).
    public let languages: [String]?
    /// List of URLs the instance exposes.
    public let urls: InstanceURLs?
    /// The account of the instance administrator.
    public let contactAccount: Account?
	public let configuration: InstanceConfiguration?

    enum CodingKeys: String, CodingKey {
        case uri, title, description, email, version, thumbnail, stats, languages, urls
        case contactAccount = "contact_account"
		case configuration
    }
}

public struct InstanceStats: Codable {
    /// Number of users registered in this instance.
    public let userCount: Int
    /// Number of statuses posted in this instance.
    public let statusCount: Int
    /// Number of domains in this instance.
    public let domainCount: Int

    enum CodingKeys: String, CodingKey {
        case userCount = "user_count"
        case statusCount = "status_count"
        case domainCount = "domain_count"
    }
}

public struct InstanceURLs: Codable {
    /// URL used for the streaming API.
    public let streaming: URL?

    enum CodingKeys: String, CodingKey {
        case streaming = "streaming_api"
    }
}

public struct InstanceConfiguration: Codable {
	public let statuses: InstanceStatusConfiguration?

	enum CodingKeys: String, CodingKey {
		case statuses
	}
}

public struct InstanceStatusConfiguration: Codable {
	public let maxCharacters: Int
	public let maxMediaAttachments: Int
	public let charactersReservedPerUrl: Int

	enum InstanceStatusConfiguration: String, CodingKey {
		case maxCharacters = "max_characters"
		case maxMediaAttachments = "max_media_attachments"
		case charactersReservedPerUrl = "characters_reserved_per_url"
	}
}
