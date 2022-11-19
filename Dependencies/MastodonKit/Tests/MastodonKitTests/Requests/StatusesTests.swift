//
//  StatusesTests.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import XCTest
@testable import MastodonKit

class StatusesTests: XCTestCase {
    func testStatus() {
        let request = Statuses.status(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testContext() {
        let request = Statuses.context(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/context")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testCard() {
        let request = Statuses.card(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/card")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testRebloggedBy() {
        let request = Statuses.rebloggedBy(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/reblogged_by")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testRebloggedByWithRange() {
        let request = Statuses.rebloggedBy(id: "42", range: .since(id: "12", limit: 50))
        let expectedSinceID = URLQueryItem(name: "since_id", value: "12")
        let expectedLimit = URLQueryItem(name: "limit", value: "50")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/reblogged_by")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertEqual(request.method.queryItems?.count, 2)
        XCTAssertTrue(request.method.queryItems!.contains(expectedSinceID))
        XCTAssertTrue(request.method.queryItems!.contains(expectedLimit))
    }

    func testFavouritedBy() {
        let request = Statuses.favouritedBy(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/favourited_by")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testFavouritedByWithRange() {
        let request = Statuses.favouritedBy(id: "42", range: .since(id: "12", limit: 50))
        let expectedSinceID = URLQueryItem(name: "since_id", value: "12")
        let expectedLimit = URLQueryItem(name: "limit", value: "50")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/favourited_by")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertEqual(request.method.queryItems?.count, 2)
        XCTAssertTrue(request.method.queryItems!.contains(expectedSinceID))
        XCTAssertTrue(request.method.queryItems!.contains(expectedLimit))
    }

    func testCreateWithMessage() {
        let request = Statuses.create(status: "The most awesome status message ever!")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "The most awesome status message ever!")
    }

    func testCreateWithMessageAndReplyID() {
        let request = Statuses.create(status: "The most awesome status message ever!", replyToID: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "The most awesome status message ever!")
        XCTAssertEqual(payload["in_reply_to_id"] as? String, "42")
    }

    func testCreateWithMessageAndMediaIDs() {
        let request = Statuses.create(status: "The most awesome status message ever!", mediaIDs: ["1", "2", "42"])

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "The most awesome status message ever!")
        XCTAssertEqual(payload["media_ids"] as? [String], ["1", "2", "42"])
    }

    func testCreateWithSensitiveMessage() {
        let request = Statuses.create(status: "The most awesome status message ever!", sensitive: true)

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "The most awesome status message ever!")
        XCTAssertEqual(payload["sensitive"] as? Bool, true)
    }

    func testCreateWithSpoilerMessage() {
        let request = Statuses.create(status: "Can't believe it's an amusement park like Westworld!", spoilerText: "Last night's GoT!!!")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "Can't believe it's an amusement park like Westworld!")
        XCTAssertEqual(payload["spoiler_text"] as? String, "Last night's GoT!!!")
    }

    func testCreateWithUnlistedMessage() {
        let request = Statuses.create(status: "The most awesome status message ever!", visibility: .unlisted)

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "unlisted")
        XCTAssertEqual(payload["status"] as? String, "The most awesome status message ever!")
    }

    func testCreateWithMessageAndPoll() {
        let request = Statuses.create(status: "What is best?",
                                      poll: PollPayload(options: ["A", "B"], expiration: 1800, multipleChoice: false))

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["visibility"] as? String, "public")
        XCTAssertEqual(payload["status"] as? String, "What is best?")

        let pollPayload = payload["poll"] as! NSDictionary
        XCTAssertEqual(pollPayload["options"] as? [String], ["A", "B"])
        XCTAssertEqual(pollPayload["expires_in"] as? Int, 1800)
        XCTAssertEqual(pollPayload["multiple"] as? Bool, false)
    }

    func testDelete() {
        let request = Statuses.delete(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42")

        // Method
        XCTAssertEqual(request.method.name, "DELETE")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testReblog() {
        let request = Statuses.reblog(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/reblog")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testUnreblog() {
        let request = Statuses.unreblog(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/unreblog")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testFavourite() {
        let request = Statuses.favourite(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/favourite")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testUnfavourite() {
        let request = Statuses.unfavourite(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/unfavourite")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testPin() {
        let request = Statuses.pin(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/pin")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testUnpin() {
        let request = Statuses.unpin(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/unpin")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testMute() {
        let request = Statuses.mute(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/mute")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testUnmute() {
        let request = Statuses.unmute(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/statuses/42/unmute")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }
}
