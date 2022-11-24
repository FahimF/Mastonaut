//
//  Client+Helpers.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 16.09.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

public extension Client {
	static func create(for account: AuthorizedAccount,
	                   keychainController: KeychainController,
	                   reauthAgent: ReauthorizationAgent,
	                   urlSession: URLSession) -> ClientType?
	{
		do {
			guard let token = try keychainController.query(authorizedAccount: account) else {
				if account.needsAuthorization == false {
					account.needsAuthorization = true
				}

				return nil
			}

			#if MOCK
				typealias FinalClient = MockClient
			#else
				typealias FinalClient = Client
			#endif

			let client = FinalClient(baseURL: "https://\(account.baseDomain!)",
			                         accessToken: token.accessToken,
			                         session: urlSession,
			                         delegate: reauthAgent)

			#if MOCK
				registerMockResponses(for: client)
			#endif

			return client
		} catch {
			if account.needsAuthorization == false {
				account.needsAuthorization = true
			}

			NSLog("Error fetching user: \(error)")

			return nil
		}
	}
}

public extension ClientType {
	@discardableResult
	func fetchAccountAndInstance(completion: @escaping (Result<(Account, Instance), ClientError>) -> Void) -> Set<FutureTask>
	{
		let dispatchGroup = DispatchGroup()
		var futures = Set<FutureTask>()
		var accountResult: MKResult<Account>?
		var instanceResult: MKResult<Instance>?

		dispatchGroup.enter()
		(run(Accounts.currentUser(), resumeImmediately: true) {
			result in

			accountResult = result

			if case let .failure(error) = result {
				NSLog("Failed getting info for current user! \(error)")
			}

			dispatchGroup.leave()
		}).map { _ = futures.insert($0) }

		dispatchGroup.enter()
		(run(Instances.current(), resumeImmediately: true) {
			result in

			instanceResult = result

			if case let .failure(error) = result {
				NSLog("Failed getting info for current instance! \(error)")
			}

			dispatchGroup.leave()
		}).map { _ = futures.insert($0) }

		dispatchGroup.notify(queue: .main) {
			switch (accountResult, instanceResult) {
			case let (.success(account, _), .success(instance, _)):
				completion(.success((account, instance)))

			default:
				let error = [accountResult?.error, instanceResult?.error].compactMap { $0 }.first!
				completion(.failure(error))
			}
		}

		return futures
	}
}
