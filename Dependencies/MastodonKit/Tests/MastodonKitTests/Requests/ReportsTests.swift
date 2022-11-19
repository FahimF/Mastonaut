//
//  ReportsTests.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import XCTest
@testable import MastodonKit

class ReportsTests: XCTestCase {
    func testAll() {
        let request = Reports.all()

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/reports")

        // Method
        XCTAssertEqual(request.method.name, "GET")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNil(request.method.httpBody)
    }

    func testReport() {
        let request = Reports.report(accountID: "40",
                                     statusIDs: ["4", "2", "42"],
                                     reason: "Westworld Spoiler!!!")

        // Endpoint
        XCTAssertEqual(request.path, "/api/v1/reports")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)
        XCTAssertNotNil(request.method.httpBody)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["account_id"] as? String, "40")
        XCTAssertEqual(payload["status_ids"] as? [String], ["4", "2", "42"])
        XCTAssertEqual(payload["comment"] as? String, "Westworld Spoiler!!!")

    }
}
