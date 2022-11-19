//
//  MediaAttachment.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum MediaAttachment {
	/// JPEG (Joint Photographic Experts Group) image
	case jpeg(Data?)
	/// GIF (Graphics Interchange Format) image
	case gif(Data?)
	/// PNG (Portable Network Graphics) image
	case png(Data?)
	/// Other media file
	case other(Data?, fileExtension: String, mimeType: String)
}

extension MediaAttachment {
	var data: Data? {
		switch self {
		case let .jpeg(data): return data
		case let .gif(data): return data
		case let .png(data): return data
		case let .other(data, _, _): return data
		}
	}

	var fileName: String {
		switch self {
		case .jpeg: return "file.jpg"
		case .gif: return "file.gif"
		case .png: return "file.png"
		case let .other(_, fileExtension, _): return "file.\(fileExtension)"
		}
	}

	var mimeType: String {
		switch self {
		case .jpeg: return "image/jpg"
		case .gif: return "image/gif"
		case .png: return "image/png"
		case let .other(_, _, mimeType): return mimeType
		}
	}

	var base64EncondedString: String? {
		return data.map { "data:" + mimeType + ";base64," + $0.base64EncodedString() }
	}
}

extension MediaAttachment: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		switch type {
		case "jpeg": self = .jpeg(try container.decodeIfPresent(Data.self, forKey: .data))
		case "gif": self = .gif(try container.decodeIfPresent(Data.self, forKey: .data))
		case "png": self = .png(try container.decodeIfPresent(Data.self, forKey: .data))
		case "other":
			self = .other(try container.decodeIfPresent(Data.self, forKey: .data),
			              fileExtension: try container.decode(String.self, forKey: .fileExtension),
			              mimeType: try container.decode(String.self, forKey: .mimeType))
		default:
			throw DecodingError.dataCorruptedError(forKey: .type,
			                                       in: container,
			                                       debugDescription: "Unknown media attachment type: \(type)")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .jpeg(data):
			try container.encode("jpeg", forKey: .type)
			try container.encodeIfPresent(data, forKey: .data)

		case let .gif(data):
			try container.encode("gif", forKey: .type)
			try container.encodeIfPresent(data, forKey: .data)

		case let .png(data):
			try container.encode("png", forKey: .type)
			try container.encodeIfPresent(data, forKey: .data)

		case let .other(data, fileExtension, mimeType):
			try container.encode("other", forKey: .type)
			try container.encodeIfPresent(data, forKey: .data)
			try container.encode(fileExtension, forKey: .fileExtension)
			try container.encode(mimeType, forKey: .mimeType)
		}
	}

	enum CodingKeys: String, CodingKey {
		case type, data, fileExtension, mimeType
	}
}

// MARK: - Form Parameter

struct FormMediaAttachment {
	var name: String
	var mediaAttachment: MediaAttachment?
}

extension FormMediaAttachment: FormParameter {
	var formItemValue: Data? {
		guard
			let data = mediaAttachment?.data,
			let mime = mediaAttachment?.mimeType,
			let filename = mediaAttachment?.fileName
		else { return nil }

		let prefix = """
		--\(Payload.formBoundary)
		Content-Disposition: form-data; name="\(name)"; filename="\(filename)"
		Content-Type: \(mime)


		""".applyingCarriageReturns
		let suffix = "\r\n"

		guard
			let prefixData = prefix.data(using: .utf8),
			let suffixData = suffix.data(using: .utf8)
		else {
			return nil
		}

		return prefixData + data + suffixData
	}
}
