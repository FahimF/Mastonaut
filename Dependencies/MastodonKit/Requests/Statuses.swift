//
//  Statuses.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Statuses` requests.
public enum Statuses {
    /// Fetches a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func status(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)")
    }

    /// Gets a status context.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Context`.
    public static func context(id: String) -> Request<Context> {
        return Request<Context>(path: "/api/v1/statuses/\(id)/context")
    }

	/// Gets the edit history of a status.
	///
	/// - Parameter id: The status id.
	/// - Returns: Request for `[StatusEdit]`.
	public static func history(id: String) -> Request<[StatusEdit]> {
		return Request<[StatusEdit]>(path: "/api/v1/statuses/\(id)/history")
	}
	
    /// Gets a card associated with a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Card`.
    public static func card(id: String) -> Request<Card> {
        return Request<Card>(path: "/api/v1/statuses/\(id)/card")
    }

    /// Gets who reblogged a status.
    ///
    /// - Parameters:
    ///   - id: The status id.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Account]`.
    public static func rebloggedBy(id: String, range: RequestRange = .default) -> Request<[Account]> {
        let parameters = range.parameters(limit: between(1, and: 80, default: 40))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Account]>(path: "/api/v1/statuses/\(id)/reblogged_by", method: method)
    }

    /// Gets who favourited a status.
    ///
    /// - Parameters:
    ///   - id: The status id.
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Account]`.
    public static func favouritedBy(id: String, range: RequestRange = .default) -> Request<[Account]> {
        let parameters = range.parameters(limit: between(1, and: 80, default: 40))
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Account]>(path: "/api/v1/statuses/\(id)/favourited_by", method: method)
    }

    /// Posts a new status.
    ///
    /// - Parameters:
    ///   - status: The text of the status.
    ///   - replyTo: The local ID of the status you want to reply to.
    ///   - mediaIDs: The array of media IDs to attach to the status (maximum 4).
    ///   - sensitive: Marks the status as NSFW.
    ///   - spoilerText: the text to be shown as a warning before the actual content.
    ///   - visibility: The status' visibility.
    /// - Returns: Request for `Status`.
    public static func create(status: String, replyToID: String? = nil, mediaIDs: [String] = [], sensitive: Bool? = nil, spoilerText: String? = nil, poll: PollPayload? = nil, visibility: Visibility = .public) -> Request<Status> {
        let parameters: [String: AnyEncodable?] = [
            "status": AnyEncodable(status),
            "in_reply_to_id": replyToID.map { AnyEncodable($0) },
            "sensitive": (sensitive ?? false) ? AnyEncodable(true) : nil,
            "spoiler_text": spoilerText.map { AnyEncodable($0) },
            "visibility": AnyEncodable(visibility.rawValue),
            "media_ids": mediaIDs.isEmpty ? nil : AnyEncodable(mediaIDs),
            "poll": poll.map { AnyEncodable($0) }
        ]
        let method = HTTPMethod.post(.json(encoding: parameters.compactMapValues { $0 }))
        return Request<Status>(path: "/api/v1/statuses", method: method)
    }

	/// Edits an existing status.
	///
	/// - Parameters:
	///   - status: The text of the status.
	///   - mediaIDs: The array of media IDs to attach to the status (maximum 4).
	///   - sensitive: Marks the status as NSFW.
	///   - spoilerText: the text to be shown as a warning before the actual content.
	///   - visibility: The status' visibility.
	/// - Returns: Request for `Status`.
	public static func edit(id: String, status: String, mediaIDs: [String] = [], sensitive: Bool? = nil, spoilerText: String? = nil, poll: PollPayload? = nil) -> Request<Status> {
		let parameters: [String: AnyEncodable?] = [
			"status": AnyEncodable(status),
			"sensitive": (sensitive ?? false) ? AnyEncodable(true) : nil,
			"spoiler_text": spoilerText.map { AnyEncodable($0) },
			"media_ids": mediaIDs.isEmpty ? nil : AnyEncodable(mediaIDs),
			"poll": poll.map { AnyEncodable($0) }
		]
		let method = HTTPMethod.put(.json(encoding: parameters.compactMapValues { $0 }))
		return Request<Status>(path: "/api/v1/statuses/\(id)", method: method)
	}
	
    /// Deletes a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Empty`.
    public static func delete(id: String) -> Request<Empty> {
        return Request<Empty>(path: "/api/v1/statuses/\(id)", method: .delete(.empty))
    }

    /// Reblogs a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func reblog(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/reblog", method: .post(.empty))
    }

    /// Unreblogs a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func unreblog(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/unreblog", method: .post(.empty))
    }

    /// Favourites a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func favourite(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/favourite", method: .post(.empty))
    }

    /// Unfavourites a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func unfavourite(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/unfavourite", method: .post(.empty))
    }

	/// Bookmarks a status.
	///
	/// - Parameter id: The status id.
	/// - Returns: Request for `Status`.
	public static func bookmark(id: String) -> Request<Status> {
		return Request<Status>(path: "/api/v1/statuses/\(id)/bookmark", method: .post(.empty))
	}

	/// Unbookmark a status.
	///
	/// - Parameter id: The status id.
	/// - Returns: Request for `Status`.
	public static func unbookmark(id: String) -> Request<Status> {
		return Request<Status>(path: "/api/v1/statuses/\(id)/unbookmark", method: .post(.empty))
	}

    /// Pins a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func pin(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/pin", method: .post(.empty))
    }

    /// Unpins a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func unpin(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/unpin", method: .post(.empty))
    }

    /// Mutes a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func mute(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/mute", method: .post(.empty))
    }

    /// Unmutes a status.
    ///
    /// - Parameter id: The status id.
    /// - Returns: Request for `Status`.
    public static func unmute(id: String) -> Request<Status> {
        return Request<Status>(path: "/api/v1/statuses/\(id)/unmute", method: .post(.empty))
    }
}
