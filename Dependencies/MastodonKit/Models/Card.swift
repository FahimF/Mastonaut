//
//  Card.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Card: Codable {
	/// The url associated with the card.
	public let url: URL
	/// The title of the card.
	public let title: String
	/// The card description.
	public let description: String?
	/// The image associated with the card, if any.
	public let imageUrl: URL?
	/// The type of the card's contents.
	public let type: Type?
	/// The name of the card content's author.
	public let authorName: String?
	/// The URL for the card content's author in string format.
	private let authorUrlString: String?
	/// The name of the card content's provider.
	public let providerName: String?
	/// The URL for the card content's provider in string format.
	private let providerUrlString: String?
	/// The card contents in HTML.
	public let html: String?
	/// The card's content width.
	public let width: Int?
	/// The card's content height.
	public let height: Int?

	/// The URL for the card content's author.
	public var authorUrl: URL? {
		guard let url = authorUrlString else { return nil }
		return URL(string: url)
	}

	/// The URL for the card content's provider.
	public var providerUrl: URL? {
		guard let url = providerUrlString else { return nil }
		return URL(string: url)
	}

	private enum CodingKeys: String, CodingKey {
		case url
		case title
		case description
		case imageUrl = "image"
		case type
		case authorName = "author_name"
		case authorUrlString = "author_url"
		case providerName = "provider_name"
		case providerUrlString = "provider_url"
		case html
		case width
		case height
	}

    public enum `Type`: String, Codable {
        case link
        case photo
        case video
        case rich
    }
}
