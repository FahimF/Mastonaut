//
//  DateFormatter.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public extension DateFormatter {
    static let mastodonFormatter: DateFormatter = MastodonDateFormatter()
}

class MastodonDateFormatter: DateFormatter {

    private let isoDateFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            dateFormatter.formatOptions = [.withInternetDateTime,
                                           .withDashSeparatorInDate,
                                           .withColonSeparatorInTime,
                                           .withTimeZone,
                                           .withFractionalSeconds]
        return dateFormatter
    }()

    override init() {
        super.init()
        timeZone = TimeZone(abbreviation: "UTC")
        locale = Locale(identifier: "en_US_POSIX")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        timeZone = TimeZone(abbreviation: "UTC")
        locale = Locale(identifier: "en_US_POSIX")
    }

    override func date(from string: String) -> Date? {
        if let date = isoDateFormatter.date(from: string) {
            return date
        }

        dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        if let date = super.date(from: string) {
            return date
        }

        dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = super.date(from: string) {
            return date
        }

        return nil
    }
}
