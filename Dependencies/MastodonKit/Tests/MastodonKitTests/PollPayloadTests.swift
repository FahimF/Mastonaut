//
//  PollPayloadTests.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 25/06/19.
//  Copyright © 2019 MastodonKit. All rights reserved.
//

import XCTest

class PollPayloadTests: XCTestCase {

    func testEncodePollPayload() {
        let payload = PollPayload(options: ["option1", "option2"], expiration: 3600, multipleChoice: true)
        let data = try! JSONEncoder().encode(payload)
        let string = String(data: data, encoding: .utf8)

        XCTAssertEqual(string, #"{"options":["option1","option2"],"expires_in":3600,"multiple":true}"#)
    }
}
