//
//  Login.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/18/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Login` requests.
public enum Login {
    /// Performs a silent login.
    ///
    /// - Parameters:
    ///   - clientID: The client ID.
    ///   - clientSecret: The client secret.
    ///   - scopes: The access scopes.
    ///   - username: The user's username or e-mail address.
    ///   - password: The user's password.
    /// - Returns: Request for `LoginSettings`.
    public static func silent(clientID: String,
                              clientSecret: String,
                              scopes: [AccessScope],
                              username: String,
                              password: String) -> Request<LoginSettings> {
        let parameters: [String: AnyEncodable] = [
            "client_id": AnyEncodable(clientID),
            "client_secret": AnyEncodable(clientSecret),
            "scope": AnyEncodable(scopes.map(toString)),
            "grant_type": AnyEncodable("password"),
            "username": AnyEncodable(username),
            "password": AnyEncodable(password)
        ]

        let method = HTTPMethod.post(.json(encoding: parameters))
        return Request<LoginSettings>(path: "/oauth/token", method: method)
    }

    /// Completes an OAuth login.
    ///
    /// - Parameters:
    ///   - clientID: The client ID.
    ///   - clientSecret: The client secret.
    ///   - scopes: The access scopes.
    ///   - redirectURI: The client redirectURI.
    ///   - code: The authorization code.
    /// - Returns: Request for `LoginSettings`.
    public static func oauth(clientID: String,
                             clientSecret: String,
                             scopes: [AccessScope],
                             redirectURI: String,
                             code: String) -> Request<LoginSettings> {
        let parameters: [String: AnyEncodable] = [
            "client_id": AnyEncodable(clientID),
            "client_secret": AnyEncodable(clientSecret),
            "scope": AnyEncodable(scopes.map(toString)),
            "grant_type": AnyEncodable("authorization_code"),
            "redirect_uri": AnyEncodable(redirectURI),
            "code": AnyEncodable(code)
        ]

        let method = HTTPMethod.post(.json(encoding: parameters))
        return Request<LoginSettings>(path: "/oauth/token", method: method)
    }
}
