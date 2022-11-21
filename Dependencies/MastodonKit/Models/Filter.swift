//
//  Filter.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 10/06/19.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// Represents a user-defined filter for determining which statuses should not be shown to the user.
public class Filter: Codable {
    /// The ID of the filter in the database.
    public let id: String
    /// The text to be filtered.
    public let phrase: String
    /// The contexts in which the filter should be applied.
    public let context: [Context]
    /// When the filter should no longer be applied.
    public let expiresAt: Date?
    /// Should matching entities in home and notifications be dropped by the server?
    public let irreversible: Bool
    /// Should the filter consider word boundaries?
    public let wholeWord: Bool

    public enum Context: Codable, RawRepresentable, Equatable {
        public typealias RawValue = String

        /// home timeline
        case home
        /// notifications timeline
        case notifications
        /// public timelines
        case `public`
        /// expanded thread of a detailed status
        case thread
        /// profiles
        case account

        case unknown(String)

        public var rawValue: String {
            switch self {
            case .account: return "account"
            case .home: return "home"
            case .notifications: return "notifications"
            case .public: return "public"
            case .thread: return "thread"
            case .unknown(let context): return context
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self.init(rawValue: rawValue)!
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "home":
                self = .home
            case "notifications":
                self = .notifications
            case "public":
                self = .public
            case "thread":
                self = .thread
            case "account":
                self = .account
            default:
                self = .unknown(rawValue)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case phrase
        case context
        case expiresAt = "expires_at"
        case irreversible
        case wholeWord = "whole_word"
    }
}
