//
//  Request.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Request<Model: Codable>: Codable {
    let path: String
    let method: HTTPMethod
    let timeout: TimeInterval?

    init(path: String, method: HTTPMethod = .get(.empty), timeout: TimeInterval? = nil) {
        self.path = path
        self.method = method
        self.timeout = timeout
    }
}
