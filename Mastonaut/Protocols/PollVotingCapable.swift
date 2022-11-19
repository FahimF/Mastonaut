//
//  PollVotingCapable.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 03.07.19.
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

import CoreTootin
import Foundation

protocol PollVotingCapable: StatusInteractionHandling {
	var client: ClientType? { get }

	var pollRefreshTimers: [String: Timer] { get set }
	var updatedPolls: [String: Poll] { get set }

	func handle(updatedPoll poll: Poll, statusID: String)
	func set(hasActivePollTask: Bool, for statusID: String)
}

extension PollVotingCapable {
	func setupRefreshTimer(for poll: Poll, statusID: String) {
		guard let refreshTime = poll.expiresAt else { return }

		pollRefreshTimers[statusID]?.invalidate()

		let timer = Timer(fire: refreshTime, interval: 1, repeats: false) {
			[weak self] _ in

			self?.pollRefreshTimers.removeValue(forKey: statusID)
			self?.refreshPoll(statusID: statusID, pollID: poll.id)
		}

		RunLoop.current.add(timer, forMode: .default)
		pollRefreshTimers[statusID] = timer
	}

	func voteOn(poll: Poll, statusID: String, options: IndexSet,
	            completion: @escaping (Swift.Result<Poll, Error>) -> Void)
	{
		guard let client = client else { return }

		PollService(client: client).voteOn(poll: poll, options: options) {
			[weak self] result in
			switch result {
			case let .success(poll):
				DispatchQueue.main.async { self?.updatedPolls[poll.id] = poll }
				completion(.success(poll))

			case let .failure(error):
				DispatchQueue.main.async { self?.refreshPoll(statusID: statusID, pollID: poll.id) }
				completion(.failure(error))
			}
		}
	}

	func refreshPoll(statusID: String, pollID: String) {
		guard let client = client else { return }

		set(hasActivePollTask: true, for: statusID)

		PollService(client: client).poll(pollID: pollID) {
			[weak self] result in

			DispatchQueue.main.async { self?.set(hasActivePollTask: false, for: statusID) }

			if case let .success(poll) = result {
				DispatchQueue.main.async { self?.handle(updatedPoll: poll, statusID: statusID) }
			}
		}
	}
}
