//
//  ClientError.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum ClientError: LocalizedError {
    /// Failed to build the URL to make the request.
    case malformedURL
    /// Failed to parse the Mastodon's JSON reponse.
    case malformedJSON
    /// Failed to parse Mastodon's model.
    case invalidModel
    /// Generic error.
    case genericError(NSError)
    /// Unauthorized
    case unauthorized
    /// Bad status.
    case badStatus(statusCode: Int)
    /// The Mastodon service returned an error.
    case mastodonError(String)

    public var errorDescription: String? {
        return localizedDescription
    }

    public var localizedDescription: String {
        switch self {
        case .malformedURL:
            return localizedString("error.mastodonkit.malformedURL")
        case .malformedJSON:
            return localizedString("error.mastodonkit.malformedJSON")
        case .invalidModel:
            return localizedString("error.mastodonkit.invalidModel")
        case .genericError(let error):
            return localizedString("error.mastodonkit.genericError", error.localizedDescription)
        case .unauthorized:
            return localizedString("error.mastodonkit.unauthorized")
        case .badStatus(let statusCode):
            return localizedString("error.mastodonkit.badStatus", statusCode)
        case .mastodonError(let errorMessage):
            return localizedString("error.mastodonkit.mastodonError", errorMessage)
        }
    }
}
