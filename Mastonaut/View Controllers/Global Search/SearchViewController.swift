//
//  SearchViewController.swift
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

import Cocoa
import CoreTootin

class SearchViewController: NSViewController {
	@objc dynamic var searchTerm: String = ""

	@objc dynamic var hasTask: Bool {
		return searchTask != nil
	}

	@objc dynamic var hasSelection: Bool {
		return userSelection != nil
	}

	private var observations: [NSKeyValueObservation] = []
	private var searchTask: FutureTask? {
		willSet { willChangeValue(for: \.hasTask) }
		didSet { didChangeValue(for: \.hasTask) }
	}

	private var userSelection: SearchResultSelection? {
		willSet { willChangeValue(for: \.hasSelection) }
		didSet { didChangeValue(for: \.hasSelection) }
	}

	private weak var resultsTabView: NSTabView?

	var client: ClientType?
	var instance: Instance?
	weak var searchDelegate: SearchViewDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()

		observations.observe(self, \.searchTerm) {
			viewController, _ in viewController.scheduleUpdateSearch()
		}
	}

	override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
		if segue.identifier == "embedResultsTabView",
		   let tabViewController = segue.destinationController as? NSTabViewController
		{
			resultsTabView = tabViewController.tabView

			observations.observe(tabViewController, \.selectedTabViewItemIndex) {
				[weak self] _, _ in self?.userSelection = nil
			}
		}
	}

	private func scheduleUpdateSearch() {
		userSelection = nil

		let selector = #selector(updateSearch)
		SearchViewController.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: nil)
		perform(selector, with: nil, afterDelay: 0.33)
	}

	@objc private func updateSearch() {
		guard let client = client else { return }

		searchTask?.task?.cancel()

		if searchTerm.isEmpty {
			handle(results: EmptyReults())
		} else {
			searchTask = dispatchSearch(client: client, searchTerm: searchTerm)
		}
	}

	private func dispatchSearch(client: ClientType, searchTerm: String) -> FutureTask? {
		let futurePromise = Promise<FutureTask>()
		let future = client.run(Search.search(query: searchTerm, resolve: true), resumeImmediately: true)
			{
				[weak self] result in

				DispatchQueue.main.async {
					guard let self = self else { return }

					if let task = futurePromise.value, self.searchTask === task {
						self.searchTask = nil
					}

					switch result {
					case let .success(results, _): self.handle(results: results)
					case let .failure(error): self.handle(error: error)
					}
				}
			}

		futurePromise.value = future
		return future
	}

	private func handle(results: ResultsType) {
		guard
			let instance = instance,
			let tabViewItems = resultsTabView?.tabViewItems
		else { return }

		for item in tabViewItems {
			guard let resultsPresenter = item.viewController as? SearchResultsPresenter else { continue }
			resultsPresenter.set(results: results, instance: instance)
			resultsPresenter.delegate = self
		}
	}

	private func handle(error _: ClientError) {
		handle(results: EmptyReults())
	}

	@IBAction func cancel(_: Any?) {
		view.window?.dismissSheetOrClose(modalResponse: .cancel)
	}

	@IBAction func showSelection(_: Any?) {
		guard let selection = userSelection else { return }
		view.window?.dismissSheetOrClose(modalResponse: .continue)
		searchDelegate?.searchView(self, userDidSelect: selection)
	}
}

extension SearchViewController: SearchResultsPresenterDelegate {
	func searchResultsPresenter(_: SearchResultsPresenter,
	                            userDidSelect selection: SearchResultSelection?)
	{
		userSelection = selection
	}

	func searchResultsPresenter(_: SearchResultsPresenter,
	                            userDidDoubleClick selection: SearchResultSelection)
	{
		assert(selection == userSelection)
		showSelection(nil)
	}
}

extension SearchViewController: NSTabViewDelegate {
	func tabView(_: NSTabView, didSelect _: NSTabViewItem?) {
		userSelection = nil
	}
}

protocol SearchViewDelegate: AnyObject {
	func searchView(_ searchView: SearchViewController, userDidSelect selection: SearchResultSelection)
}

protocol ResultsType {
	var accounts: [Account] { get }
	var statuses: [Status] { get }
	var hashtags: [Tag] { get }
}

struct EmptyReults: ResultsType {
	var accounts: [Account] { return [] }
	var statuses: [Status] { return [] }
	var hashtags: [Tag] { return [] }
}

extension Results: ResultsType {}
