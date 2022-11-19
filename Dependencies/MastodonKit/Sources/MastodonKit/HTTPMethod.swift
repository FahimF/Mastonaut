//
//  HTTPMethod.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/28/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

enum HTTPMethod {
	case get(Payload)
	case post(Payload)
	case put(Payload)
	case patch(Payload)
	case delete(Payload)
}

extension HTTPMethod {
	var name: String {
		switch self {
		case .get: return "GET"
		case .post: return "POST"
		case .put: return "PUT"
		case .delete: return "DELETE"
		case .patch: return "PATCH"
		}
	}

	var queryItems: [URLQueryItem]? {
		switch self {
		case let .get(payload): return payload.items
		default: return nil
		}
	}

	var httpBody: Data? {
		switch self {
		case let .post(payload): return payload.data
		case let .put(payload): return payload.data
		case let .patch(payload): return payload.data
		case let .delete(payload): return payload.data
		default: return nil
		}
	}

	var contentType: String? {
		switch self {
		case let .post(payload): return payload.type
		case let .put(payload): return payload.type
		case let .patch(payload): return payload.type
		case let .delete(payload): return payload.type
		default: return nil
		}
	}
}

extension HTTPMethod: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		switch type {
		case "get":
			self = .get(try container.decode(Payload.self, forKey: .payload))
		case "post":
			self = .post(try container.decode(Payload.self, forKey: .payload))
		case "put":
			self = .put(try container.decode(Payload.self, forKey: .payload))
		case "patch":
			self = .patch(try container.decode(Payload.self, forKey: .payload))
		case "delete":
			self = .delete(try container.decode(Payload.self, forKey: .payload))
		default:
			throw DecodingError.dataCorruptedError(forKey: .type,
			                                       in: container,
			                                       debugDescription: "Unknwon method type: \(type)")
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .get(payload):
			try container.encode("get", forKey: .type)
			try container.encode(payload, forKey: .payload)
		case let .post(payload):
			try container.encode("post", forKey: .type)
			try container.encode(payload, forKey: .payload)
		case let .put(payload):
			try container.encode("put", forKey: .type)
			try container.encode(payload, forKey: .payload)
		case let .patch(payload):
			try container.encode("patch", forKey: .type)
			try container.encode(payload, forKey: .payload)
		case let .delete(payload):
			try container.encode("delete", forKey: .type)
			try container.encode(payload, forKey: .payload)
		}
	}

	enum CodingKeys: String, CodingKey {
		case type, payload
	}
}
