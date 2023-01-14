//
//  ReplaceCharactersTests.swift
//  MastonautTests
//
//  Created by Sören Kuklau on 31.12.22.
//  Copyright © 2022 Bruno Philipe. All rights reserved.
//

import Foundation
import XCTest

class ReplaceCharactersTests: XCTestCase {
	fileprivate func _replaceAndAssert(input: String, expected: String, range: [NSRange: String]) {
		let output = NSMutableString(string: input)
		output.replaceCharacters(in: range)
		
		let actual = String(output)
		
		XCTAssertEqual(expected, actual)
	}
	
	func testWithEmptyRange() {
		let input = "hello"
		let range = [NSRange(location: 0, length: 0): ""]
		
		_replaceAndAssert(input: input, expected: input, range: range)
	}
	
	func testRemoveRemainder() {
		let input = "prefix removeme"
		let range = [NSRange(location: 6, length: 9): ""]
		
		_replaceAndAssert(input: input, expected: "prefix", range: range)
	}
	
	func testWithSuffix() {
		let input = "prefix replaceme suffix"
		let range = [NSRange(location: 7, length: 9): "replaced"]
		
		_replaceAndAssert(input: input, expected: "prefix replaced suffix", range: range)
	}
	
	func testHardcodedurlMidfix() {
		let input = "hello http://example.com goodbye"
		let range = [NSRange(location: 6, length: 18): ReplaceCharactersTests.linkPlaceholder]

		_replaceAndAssert(input: input, expected: "hello \(ReplaceCharactersTests.linkPlaceholder) goodbye", range: range)
	}
	
	fileprivate func enumerateUrlMatches(_ mutableCopy: NSMutableString, _ replacementRanges: inout [_NSRange : String]) {
		NSRegularExpression.uriRegex.enumerateMatches(in: mutableCopy as String, options: [], range: mutableCopy.range)
		{
			result, _, _ in
			
			guard let result = result, result.numberOfRanges > 1 else {
				return
			}
			
			let prefix = mutableCopy.substring(with: result.range(at: 1))
			let suffix = mutableCopy.substring(with: result.range(at: result.numberOfRanges - 1))
			replacementRanges[result.range] = "\(prefix)\(ReplaceCharactersTests.linkPlaceholder)\(suffix)"
		}
	}
	
	func testUrlPrefix() {
		let input = "http://example.com goodbye"
		
		let mutableCopy = (input as NSString).mutableCopy() as! NSMutableString
		var replacementRanges: [NSRange: String] = [:]
		
		enumerateUrlMatches(mutableCopy, &replacementRanges)
		
		mutableCopy.replaceCharacters(in: replacementRanges)
		
		XCTAssertEqual("\(ReplaceCharactersTests.linkPlaceholder) goodbye", String(mutableCopy))
	}
	
	func testUrlMidfix() {
		let input = "hello http://example.com goodbye"
		
		let mutableCopy = (input as NSString).mutableCopy() as! NSMutableString
		var replacementRanges: [NSRange: String] = [:]
		
		enumerateUrlMatches(mutableCopy, &replacementRanges)
		
		mutableCopy.replaceCharacters(in: replacementRanges)
		
		XCTAssertEqual("hello \(ReplaceCharactersTests.linkPlaceholder) goodbye", String(mutableCopy))
	}
	
	func testUrlSuffix() {
		let input = "hello http://example.com"
		
		let mutableCopy = (input as NSString).mutableCopy() as! NSMutableString
		var replacementRanges: [NSRange: String] = [:]
		
		enumerateUrlMatches(mutableCopy, &replacementRanges)
		
		mutableCopy.replaceCharacters(in: replacementRanges)
		
		XCTAssertEqual("hello \(ReplaceCharactersTests.linkPlaceholder)", String(mutableCopy))
	}
	
	static let linkPlaceholder = String(repeating: "x", count: 23)
}
