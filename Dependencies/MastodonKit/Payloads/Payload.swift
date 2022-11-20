//
//  Payload.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/28/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

enum Payload {
    case parameters([Parameter]?)
    case form([FormParameter]?)
    case json(AnyEncodable)
    case media(MediaAttachment?)
    case empty
}

extension Payload {
    static func json<T: Encodable>(encoding object: T) -> Payload {
        return .json(AnyEncodable(object))
    }
}

extension Payload {
    static let formBoundary = "xAb54_MastodonKit_xAb54"

    var items: [URLQueryItem]? {
        switch self {
        case .parameters(let parameters): return parameters?.compactMap(toQueryItem)
        case .form, .media, .empty, .json: return nil
        }
    }

    var data: Data? {
        switch self {
        case .parameters(let parameters):
            return parameters?.compactMap(toString).joined(separator: "&").data(using: .utf8)

        case .form(let parameters):
            return parameters?.compactMap({ $0.formItemValue })
                .reduce(Data(), +)
                .appending("--\(Payload.formBoundary)--")

        case .json(let encodable):
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .formatted(.mastodonFormatter)
            return try? jsonEncoder.encode(encodable)

        case .media(let mediaAttachment):
            return mediaAttachment.flatMap(Data.init)

        case .empty:
            return nil
        }
    }

    var type: String? {
        switch self {
        case .parameters(.some):
            return "application/x-www-form-urlencoded; charset=utf-8"

        case .json:
            return "application/json"

        case .media(.some), .form(.some):
            return "multipart/form-data; boundary=\(Payload.formBoundary)"

        case .parameters(.none), .media(.none), .form(.none), .empty:
            return nil
        }
    }
}

extension Payload: Codable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .parameters(let parameters):
            try container.encode("parameters", forKey: .type)
            try container.encodeIfPresent(parameters, forKey: .parameters)

        case .json(let encodable):
            try container.encode("json", forKey: .type)
            try container.encode(encodable, forKey: .parameters)

        case .form:
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [CodingKeys.type],
                                                                         debugDescription: "Form couldn't be encoded"))

        case .media(let media):
            try container.encode("media", forKey: .type)
            try container.encodeIfPresent(media, forKey: .media)

        case .empty:
            try container.encode("empty", forKey: .type)

        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "parameters":
            self = .parameters(try container.decodeIfPresent([Parameter].self, forKey: .parameters))

        case "media":
            self = .media(try container.decodeIfPresent(MediaAttachment.self, forKey: .media))

        case "json":
            self = .json(AnyEncodable(try container.decode(Data.self, forKey: .parameters)))

        case "empty":
            self = .empty

        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Payload type not supported: \(type)")
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, parameters, media
    }
}

protocol FormParameter: Codable {
    var formItemValue: Data? { get }
}
