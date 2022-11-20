//
//  PollOption.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 03/04/19.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct PollOption: Codable {
    /// The title of the poll option.
    public let title: String
    /// The number of votes this option received, if any.
    public let votesCount: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case votesCount = "votes_count"
    }
}
