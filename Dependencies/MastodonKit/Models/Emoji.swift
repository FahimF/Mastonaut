//
//  Emoji.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 1/1/18.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Emoji: Codable {
    /// The shortcode of the emoji
    public let shortcode: String
    /// URL to the emoji static image
    public let staticURL: URL
    /// URL to the emoji image
    public let url: URL
    /// Whether the emoji should be shown in the composer emoji picker.
    public let visibleInPicker: Bool?

    public init(shortcode: String, staticURL: URL, url: URL, visibleInPicker: Bool) {
        self.shortcode = shortcode
        self.staticURL = staticURL
        self.url = url
        self.visibleInPicker = visibleInPicker
    }

    private enum CodingKeys: String, CodingKey {
        case shortcode
        case staticURL = "static_url"
        case url
        case visibleInPicker = "visible_in_picker"
    }
}
