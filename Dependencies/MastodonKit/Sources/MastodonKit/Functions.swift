//
//  Functions.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/13/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

// MARK: - Map

func toString(scope: AccessScope) -> String {
    return scope.rawValue
}

func toDictionaryOfParameters<D: StringDictionaryConvertible>(withName name: String) -> ([D]) -> [Parameter] {
	return { array in
		var parameters = [Parameter]()

		for (index, element) in array.enumerated() {
			for (key, value) in element.dictionaryValue {
				parameters.append(Parameter(name: "\(name)[\(index)][\(key)]", value: value))
			}
		}

		return parameters
	}
}

func toArrayOfParameters<A>(withName name: String) -> (A) -> Parameter {
    return { value in Parameter(name: "\(name)[]", value: String(describing: value)) }
}

func between(_ min: Int, and max: Int, default: Int) -> (Int) -> Int {
    return { limit in (limit >= min && limit <= max) ? limit : `default` }
}

// MARK: - Flat-map

func toOptionalString<A>(optional: A?) -> String? {
    return optional.map(String.init(describing:))
}

func toQueryItem(parameter: Parameter) -> URLQueryItem? {
    guard let value = parameter.value else { return nil }
    return URLQueryItem(name: parameter.name, value: value)
}

func toString(parameter: Parameter) -> String? {
    return parameter.value?
        .addingPercentEncoding(withAllowedCharacters: .bodyAllowed)
        .map { value in "\(parameter.name)=\(value)" }
}

func trueOrNil(_ flag: Bool) -> String? {
    return flag ? "true" : nil
}

func toString(_ flag: Bool) -> String {
	return flag ? "true" : "false"
}

func trim(left: Character, right: Character) -> (String) -> String {
    return { string in
        guard string.hasPrefix("\(left)"), string.hasSuffix("\(right)") else { return string }
        return String(string[string.index(after: string.startIndex)..<string.index(before: string.endIndex)])
    }
}

func toInteger(item: URLQueryItem) -> Int? {
    guard let value = item.value else { return nil }
    return Int(value)
}

func toAccessScope(string: String) -> AccessScope? {
    return AccessScope(rawValue: string)
}

protocol StringDictionaryConvertible {
    var dictionaryValue: [(key: String, value: String)] { get }
}

func localizedString(_ key: String, _ parameters: Any...) -> String {
    let formatString = Bundle(for: MastodonError.self).localizedString(forKey: key, value: nil, table: nil)
    return String(format: formatString, arguments: parameters.map { "\($0)" })
}
