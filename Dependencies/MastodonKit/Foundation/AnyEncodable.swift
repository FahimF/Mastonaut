//
//  AnyEncodable.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 25/06/19.
//  Copyright © 2019 MastodonKit. All rights reserved.
//

import Foundation

struct AnyEncodable: Encodable {

    private let encodeImpl: (Encoder) throws -> Void

    init<T: Encodable>(_ object: T) {
        encodeImpl = { try object.encode(to: $0) }
    }

    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }

}
