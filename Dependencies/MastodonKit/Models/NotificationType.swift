//
//  NotificationType.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum NotificationType: Codable, RawRepresentable, Equatable {

    public typealias RawValue = String

    /// The user has been mentioned.
    case mention
    /// The status message has been reblogged.
    case reblog
    /// The status message has been favourited.
    case favourite
    /// The user has a new follower.
    case follow
    /// A poll has ended
    case poll

    /// An unknown notification type
    case other(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "mention": self = .mention
        case "reblog": self = .reblog
        case "favourite": self = .favourite
        case "follow": self = .follow
        case "poll": self = .poll
        case let other: self = .other(other)
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "mention": self = .mention
        case "reblog": self = .reblog
        case "favourite": self = .favourite
        case "follow": self = .follow
        case "poll": self = .poll
        case let other: self = .other(other)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .mention: try container.encode("mention")
        case .reblog: try container.encode("reblog")
        case .favourite: try container.encode("favourite")
        case .follow: try container.encode("follow")
        case .poll: try container.encode("poll")
        case .other(let other): try container.encode(other)
        }
    }

    public var rawValue: String {
        switch self {
        case .mention: return "mention"
        case .reblog: return "reblog"
        case .favourite: return "favourite"
        case .follow: return "follow"
        case .poll: return "poll"
        case .other(let other): return other
        }
    }
}
