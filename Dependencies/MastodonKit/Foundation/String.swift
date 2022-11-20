//
//  String.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/31/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

extension String {
    func condensed(separator: String = "") -> String {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter { !$0.isEmpty }.joined(separator: separator)
    }

    private static let nonCGNLRegex = try? NSRegularExpression(pattern: "(?<=[^\\r])\\n", options: [])

    var applyingCarriageReturns: String {
        let mutableString = NSMutableString(string: self)
        String.nonCGNLRegex?.replaceMatches(in: mutableString,
                                            options: [],
                                            range: NSRange(location: 0, length: mutableString.length),
                                            withTemplate: "\r\n")
        return mutableString as String
    }
}
