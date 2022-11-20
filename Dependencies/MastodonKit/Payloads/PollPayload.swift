//
//  PollPayload.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 25/06/19.
//  Copyright © 2019 MastodonKit. All rights reserved.
//

import Foundation

public struct PollPayload: Codable {
    let options: [String]
    let expiration: TimeInterval
    let multipleChoice: Bool

    public init(options: [String], expiration: TimeInterval, multipleChoice: Bool) {
        self.options = options
        self.expiration = expiration
        self.multipleChoice = multipleChoice
    }

    enum CodingKeys: String, CodingKey {
        case options
        case expiration = "expires_in"
        case multipleChoice = "multiple"
    }
}
