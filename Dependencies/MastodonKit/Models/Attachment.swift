//
//  Attachment.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Attachment: Codable {
    /// ID of the attachment.
    public let id: String
    /// Type of the attachment.
    public let type: AttachmentType
    /// URL of the locally hosted version of the image.
    public let url: String
    /// For remote images, the remote URL of the original image.
    public let remoteURL: String?
    /// URL of the preview image.
    public let previewURL: String?
    /// Shorter URL for the image, for insertion into text (only present on local images).
    public let textURL: String?
    /// A description of the image for the visually impaired.
    public let description: String?
    /// Metadata about the attachment. Not always available.
    public let meta: MetaCollection?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case url
        case remoteURL = "remote_url"
        case previewURL = "preview_url"
        case textURL = "text_url"
        case description
        case meta
    }

    public struct MetaCollection: Codable {
        /// Metadata about the original resource
        public let original: AttachmentMetadata?

        /// Metadata about the small resource thumbnail
        public let small: AttachmentMetadata?

        /// The focus point of the original resource. Can be used for smart cropping.
        public let focus: AttachmentFocusPoint?
    }
}

public struct AttachmentMetadata: Codable {
    /// The width of the image or video attachment
    public let width: Int?

    /// The height of the image or video attachment
    public let height: Int?

    /// The duration of media attachments
    public let duration: Double?

    /// The bitrate of media attachments
    public let bitrate: Int?
}

public struct AttachmentFocusPoint: Codable {
    /// The X coordinate of the focus point.
    public let centerX: Float

    /// The Y coordinate of the focus point.
    public let centerY: Float

    enum CodingKeys: String, CodingKey {
        case centerX = "x"
        case centerY = "y"
    }
}
