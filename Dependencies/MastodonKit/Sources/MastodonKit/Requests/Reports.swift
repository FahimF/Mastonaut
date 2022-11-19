//
//  Reports.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Reports` requests.
public enum Reports {
	/// Fetches a user's reports.
	///
	/// - Returns: Request for `[Report]`.
	public static func all() -> Request<[Report]> {
		return Request<[Report]>(path: "/api/v1/reports")
	}

	/// Reports a user.
	///
	/// - Parameters:
	///   - accountID: The ID of the account to report.
	///   - statusIDs: The IDs of statuses to report.
	///   - reason: A comment to associate with the report.
	/// - Returns: Request for `Report`.
	public static func report(accountID: String, statusIDs: [String], reason: String) -> Request<Report> {
		let parameters: [String: AnyEncodable] = [
			"account_id": AnyEncodable(accountID),
			"comment": AnyEncodable(reason),
			"status_ids": AnyEncodable(statusIDs),
		]

		let method = HTTPMethod.post(.json(encoding: parameters))
		return Request<Report>(path: "/api/v1/reports", method: method)
	}
}
