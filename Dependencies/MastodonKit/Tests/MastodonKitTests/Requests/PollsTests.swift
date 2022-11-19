//
//  PollsTests.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 18/06/19.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

import XCTest
@testable import MastodonKit

class PollsTests: XCTestCase {
    func testGetPoll() {
        let request = Polls.poll(id: "an-id")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/polls/an-id")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNil(request.method.httpBody)
    }

    func testVoteOnPoll() {
        let request = Polls.vote(pollID: "an-id", optionIndices: IndexSet(integer: 1))

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/polls/an-id/votes")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload, #"{"choices":["1"]}"#)
    }

    func testVoteOnPollMultipleChoice() {
        let request = Polls.vote(pollID: "an-id", optionIndices: IndexSet(arrayLiteral: 1, 3, 4))

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/polls/an-id/votes")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload, #"{"choices":["1","3","4"]}"#)
    }
}
