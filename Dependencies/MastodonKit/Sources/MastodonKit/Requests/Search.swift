//
//  Search.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Search` requests.
public enum Search {
    /// Searches for content. Only available from Mastodon version 2.4.1.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - limit: The count limit of results to return.
    ///   - resolve: Whether to resolve non-local accounts.
    /// - Returns: Request for `Results`.
    public static func search(query: String, limit: Int? = nil, resolve: Bool? = nil) -> Request<Results> {
        let toLimitBounds = between(1, and: 80, default: 40)
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "resolve", value: resolve.flatMap(trueOrNil)),
            Parameter(name: "limit", value: limit.map(toLimitBounds).flatMap(toOptionalString))
        ]

        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v2/search", method: method)
    }

    /// Searches for content using the v1 API.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - resolve: Whether to resolve non-local accounts.
    /// - Returns: Request for `Results`.
    public static func fallbackSearch(query: String, resolve: Bool? = nil) -> Request<Results> {
        let parameters = [
            Parameter(name: "q", value: query),
            Parameter(name: "resolve", value: resolve.flatMap(trueOrNil))
        ]

        let method = HTTPMethod.get(.parameters(parameters))
        return Request<Results>(path: "/api/v1/search", method: method)
    }
}
