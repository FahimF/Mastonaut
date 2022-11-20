//
//  Tag.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Tag: Codable {
    /// The hashtag, not including the preceding #.
    public let name: String
    /// The URL of the hashtag.
    public let url: URL
    /// A log of statistics for this specific tag for previous days.
    public let history: [TagStatistics]?
}

public class TagStatistics: Codable {
    public let day: Date
    public let uses: Int
    public let accounts: Int

    // This type is a mess in the API, where everything is a string...
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let dayStamp = Int(try container.decode(String.self, forKey: .day)) else {
            throw DecodingError.dataCorruptedError(forKey: .day, in: container,
                                                   debugDescription: "`day` does not seem to be a valid integer")
        }
        self.day = Date(timeIntervalSince1970: TimeInterval(dayStamp))

        guard let uses = Int(try container.decode(String.self, forKey: .uses)) else {
            throw DecodingError.dataCorruptedError(forKey: .uses, in: container,
                                                   debugDescription: "`uses` does not seem to be a valid integer")
        }
        self.uses = uses

        guard let accounts = Int(try container.decode(String.self, forKey: .accounts)) else {
            throw DecodingError.dataCorruptedError(forKey: .accounts, in: container,
                                                   debugDescription: "`accounts` does not seem to be a valid integer")
        }
        self.accounts = accounts
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(Int(day.timeIntervalSince1970))", forKey: .day)
        try container.encode("\(uses)", forKey: .uses)
        try container.encode("\(accounts)", forKey: .accounts)
    }

    enum CodingKeys: String, CodingKey {
        case day
        case uses
        case accounts
    }
}
