//
//  DomainBlocks.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 6/5/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `DomainBlocks` requests.
public enum DomainBlocks {
	/// Fetches a user's blocked domains.
	///
	/// - Parameter range: The bounds used when requesting data from Mastodon.
	/// - Returns: Request for `[String]`.
	public static func all(range: RequestRange = .default) -> Request<[String]> {
		let parameters = range.parameters(limit: between(1, and: 80, default: 40))
		let method = HTTPMethod.get(.parameters(parameters))

		return Request<[String]>(path: "/api/v1/domain_blocks", method: method)
	}

	/// Blocks a domain.
	///
	/// - Parameter domain: The domain to block.
	/// - Returns: Request for `Empty`.
	public static func block(domain: String) -> Request<Empty> {
		let method = HTTPMethod.post(.json(encoding: ["domain": domain]))

		return Request<Empty>(path: "/api/v1/domain_blocks", method: method)
	}

	/// Unblocks a domain.
	///
	/// - Parameter domain: The domain to unblock.
	/// - Returns: Request for `Empty`.
	public static func unblock(domain: String) -> Request<Empty> {
		let method = HTTPMethod.delete(.json(encoding: ["domain": domain]))

		return Request<Empty>(path: "/api/v1/domain_blocks", method: method)
	}
}
