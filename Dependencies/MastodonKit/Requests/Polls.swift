//
//  Polls.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 17/06/19.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum Polls {

    public static func poll(id: String) -> Request<Poll> {
        return Request(path: "/api/v1/polls/\(id)")
    }

    public static func vote(pollID: String, optionIndices: IndexSet) -> Request<Poll> {
        let method = HTTPMethod.post(.json(encoding: ["choices": optionIndices.map { "\($0)" }]))
        return Request<Poll>(path: "/api/v1/polls/\(pollID)/votes", method: method)
    }
}
