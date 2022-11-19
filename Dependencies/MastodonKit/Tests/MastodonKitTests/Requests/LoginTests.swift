//
//  LoginTests.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import XCTest
@testable import MastodonKit

class LoginTests: XCTestCase {
    func testSilentLogin() {
        let request = Login.silent(clientID: "client id", clientSecret: "client secret", scopes: [.read, .write], username: "foo", password: "123")

        // Endpoint
        XCTAssertEqual(request.path, "/oauth/token")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["username"] as? String, "foo")
        XCTAssertEqual(payload["scope"] as? [String], ["read", "write"])
        XCTAssertEqual(payload["password"] as? String, "123")
        XCTAssertEqual(payload["client_id"] as? String, "client id")
        XCTAssertEqual(payload["client_secret"] as? String, "client secret")
        XCTAssertEqual(payload["grant_type"] as? String, "password")
    }

    func testOAuthLogin() {
        let request = Login.oauth(clientID: "client id", clientSecret: "client secret", scopes: [.read, .write], redirectURI: "foo://oauth", code: "123")

        // Endpoint
        XCTAssertEqual(request.path, "/oauth/token")

        // Method
        XCTAssertEqual(request.method.name, "POST")
        XCTAssertNil(request.method.queryItems)

        let payload = try! JSONSerialization.jsonObject(with: request.method.httpBody!, options: []) as! NSDictionary
        XCTAssertEqual(payload["client_id"] as? String, "client id")
        XCTAssertEqual(payload["client_secret"] as? String, "client secret")
        XCTAssertEqual(payload["scope"] as? [String], ["read", "write"])
        XCTAssertEqual(payload["grant_type"] as? String, "authorization_code")
        XCTAssertEqual(payload["redirect_uri"] as? String, "foo://oauth")
        XCTAssertEqual(payload["code"] as? String, "123")
    }
}
