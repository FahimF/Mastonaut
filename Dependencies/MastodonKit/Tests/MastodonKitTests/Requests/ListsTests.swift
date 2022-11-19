//
//  ListsTests.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 1/2/18.
//  Copyright © 2018 MastodonKit. All rights reserved.
//

import XCTest
@testable import MastodonKit

class ListsTests: XCTestCase {
    func testAll() {
        let request = Lists.all()

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testAccountsInList() {
        let request = Lists.accounts(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42/accounts")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testList() {
        let request = Lists.list(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.httpBody)
        XCTAssertNil(request.method.queryItems)
    }

    func testCreate() {
        let request = Lists.create(title: "awesome list")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload, #"{"title":"awesome list"}"#)
    }

    func testUpdate() {
        let request = Lists.update(id: "42", title: "awesome title")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42")

        // Method
        XCTAssertEqual(request.method.name, "PUT")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload.components(separatedBy: "&").count, 1)
        XCTAssertEqual(payload, #"{"title":"awesome title"}"#)
    }

    func testDelete() {
        let request = Lists.delete(id: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42")

        // Method
        XCTAssertEqual(request.method.name, "DELETE")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNil(request.method.httpBody)
    }

    func testAdd() {
        let request = Lists.add(accountIDs: ["1", "2", "3"], toList: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42/accounts")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload, #"{"account_ids":["1","2","3"]}"#)
    }

    func testRemove() {
        let request = Lists.remove(accountIDs: ["1", "2", "3"], fromList: "42")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/lists/42/accounts")

        // Method
        XCTAssertEqual(request.method.name, "DELETE")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = String(data: request.method.httpBody!, encoding: .utf8)!
        XCTAssertEqual(payload, #"{"account_ids":["1","2","3"]}"#)
    }
}
