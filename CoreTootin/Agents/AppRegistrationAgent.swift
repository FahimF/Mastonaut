//
//  AppRegistrationAgent.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 05.10.19.
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

import Foundation

public class AppRegistrationAgent {
	private unowned let keychainController: KeychainController

	public init(keychainController: KeychainController) {
		self.keychainController = keychainController
	}

	public func clientAppRegistration(for baseDomain: String,
	                                  completion: @escaping (Swift.Result<ClientApplication, Errors>) -> Void)
	{
		if let clientApplication = keychainController.clientAppRegistration(for: baseDomain) {
			completion(.success(clientApplication))
		} else {
			registerApplication(onInstance: baseDomain) {
				[weak self] result in

				guard let self = self else { return }

				DispatchQueue.main.async {
					switch result {
					case let .success(clientApplication):
						self.keychainController.register(clientApplication: clientApplication, for: baseDomain)
						completion(.success(clientApplication))

					case let .failure(error):
						completion(.failure(error))
					}
				}
			}
		}
	}

	private func redirectUri(for baseDomain: String) -> String {
		return "mastonaut-auth://oauth/grant/\(baseDomain)/code/"
	}

	private func registerApplication(onInstance baseDomain: String,
	                                 completion: @escaping (Swift.Result<ClientApplication, Errors>) -> Void)
	{
		let client = Client(baseURL: "https://" + baseDomain)

		client.run(Clients.register(clientName: "Mastonaut",
		                            redirectURI: redirectUri(for: baseDomain),
		                            scopes: [.read, .write, .push, .follow],
		                            website: "https://www.mastonaut.app")) {
			result in

			switch result {
			case let .failure(error):
				completion(.failure(.restError(error.localizedDescription)))

			case let .success(registration, _):
				completion(.success(registration))
			}
		}
	}

	public enum Errors: Error {
		case restError(String)
		case keychainError(Error)
		case unknownAuthorization

		var localizedDescription: String {
			switch self {
			case let .restError(error): return "REST: \(error)"
			case let .keychainError(error): return "Keychain: \(error.localizedDescription)"
			case .unknownAuthorization: return 🔠("authorization.unknown")
			}
		}
	}
}

private extension KeychainController {
	func clientAppRegistration(for instanceBaseUrl: String) -> ClientApplication? {
		do {
			let registration: InstanceRegistration? = try query(account: instanceBaseUrl)

			if registration?.client.redirectURI.contains("https://www.mastonaut.app") == true {
				// This is a bad registration which won't work anymore. It should be deleted.
				try delete(instanceBaseUrl)
				return nil
			}

			return registration?.client
		} catch {
			NSLog("Failed fetching instance registration for instance “\(instanceBaseUrl)”: \(error.localizedDescription)")
			return nil
		}
	}

	func register(clientApplication: ClientApplication, for instanceBaseUrl: String) {
		do {
			try store(InstanceRegistration(account: instanceBaseUrl, client: clientApplication))
		} catch {
			NSLog("Failed storing registration for instance “\(instanceBaseUrl)”: \(error.localizedDescription)")
		}
	}

	func deleteRegistration(for instanceBaseUrl: String) {
		do {
			guard let registration: InstanceRegistration = try? query(account: instanceBaseUrl) else { return }
			try delete(registration)
		} catch {
			NSLog("Failed deleting registration for instance “\(instanceBaseUrl)”: \(error.localizedDescription)")
		}
	}

	/// Stores the app registration with an individual instance.
	struct InstanceRegistration: KeychainStorable {
		let account: String
		let client: ClientApplication
	}
}
