//
//  Parameter.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/2/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

struct Parameter {
    let name: String
    let value: String?
}

// MARK: - Equatable

extension Parameter: Equatable {}

// MARK: - Form Parameter

extension Parameter: FormParameter {

	var formItemValue: Data? {
		guard let value = self.value else { return nil }
		return """
--\(Payload.formBoundary)
Content-Disposition: form-data; name="\(name)"

\(value)

""".applyingCarriageReturns.data(using: .utf8)
	}
}

extension Parameter: Codable {
}
