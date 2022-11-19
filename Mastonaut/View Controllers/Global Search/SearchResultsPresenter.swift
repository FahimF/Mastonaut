//
//  SearchResultsPresenter.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.06.19.
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

import AppKit
import CoreTootin

protocol SearchResultsPresenter: NSViewController {
	var delegate: SearchResultsPresenterDelegate? { get set }

	func set(results: ResultsType, instance: Instance)
}

protocol SearchResultsPresenterDelegate: AnyObject {
	func searchResultsPresenter(_ presenter: SearchResultsPresenter, userDidSelect selection: SearchResultSelection?)
	func searchResultsPresenter(_ presenter: SearchResultsPresenter, userDidDoubleClick selection: SearchResultSelection)
}

enum SearchResultSelection: Equatable {
	case account(Account)
	case status(Status)
	case tag(String)

	static func == (lhs: SearchResultSelection, rhs: SearchResultSelection) -> Bool {
		switch (lhs, rhs) {
		case let (.account(a1), .account(a2)):
			return a1.id == a2.id

		case let (.status(s1), .status(s2)):
			return s1.id == s2.id

		case let (.tag(t1), .tag(t2)):
			return t1 == t2

		default:
			return false
		}
	}
}
