//
//  Media.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Media` requests.
public enum Media {
    /// Uploads a media attachment.
    ///
    /// - Parameter mediaAttachment: The media attachment to upload.
    /// - Returns: Request for `Attachment`.
    public static func upload(media mediaAttachment: MediaAttachment) -> Request<Attachment> {
        let method = HTTPMethod.post(.media(mediaAttachment))
        return Request<Attachment>(path: "/api/v1/media", method: method, timeout: 60 * 10)
    }

    /// Update a media attachment. Can only be done before the media is attached to a status.
    ///
    /// - Parameters:
    ///   - id: The media attachment id to update.
    ///   - description: A plain-text description of the media for accessibility (max 420 chars)
    /// - Returns: Request for `Attachment`.
    public static func update(id: String, description: String? = nil) -> Request<Attachment> {
        let parameters = [
            Parameter(name: "description", value: description)
        ]

        let method = HTTPMethod.put(.parameters(parameters))
        return Request<Attachment>(path: "/api/v1/media/\(id)", method: method)
    }
}
