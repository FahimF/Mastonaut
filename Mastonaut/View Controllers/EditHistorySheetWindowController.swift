//
//  EditHistorySheetWindowController.swift
//  Mastonaut
//
//  Created by Sören Kuklau on 07.01.23.
//  Copyright © 2023 Bruno Philipe. All rights reserved.
//

import CoreTootin
import Foundation

class EditHistoryViewController: NSViewController, BaseColumnViewController, SidebarPresentable, NSTableViewDataSource, NSTableViewDelegate {
	var currentFocusRegion: NSRect?

	func activateKeyboardNavigation(preferredFocusRegion: NSRect?) {
		guard tableView.selectedRowIndexes.isEmpty, let statusHistory, statusHistory.isEmpty == false else {
			return
		}
		tableView.selectFirstVisibleRow()
	}

	init(status: Status?, edits: [StatusEdit]?) {
		self.status = status
		self.statusHistory = edits?.reversed()
		super.init(nibName: "EditHistorySheetWindowController", bundle: .main)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func containerWindowOcclusionStateDidChange(_ occlusionState: NSWindow.OcclusionState) {}

	var mainResponder: NSResponder {
		return tableView
	}

	var sidebarModelValue: SidebarModel {
		return SidebarMode.edits(status: status, edits: statusHistory)
	}

	var client: ClientType?

	var titleMode: SidebarTitleMode {
		return .title(🔠("Edits"))
	}

	@IBOutlet var highlightDifferences: NSButton!
	@IBOutlet private(set) var tableView: NSTableView!

	var status: Status?
	var statusHistory: [StatusEdit]? = []

	enum CellViewIdentifiers {
		static let editedStatus = NSUserInterfaceItemIdentifier("editedStatus")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(NSNib(nibNamed: "EditedStatusTableCellView", bundle: .main), forIdentifier: CellViewIdentifiers.editedStatus)
	}

	// MARK: - Table View Data Source
	func numberOfRows(in tableView: NSTableView) -> Int {
		guard let statusHistory else { return 0 }
		return statusHistory.count
	}

	@IBAction func toggleHighlightDifferences(_ sender: NSButton) {
		tableView.reloadData()
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let _cellView = tableView.makeView(withIdentifier: CellViewIdentifiers.editedStatus, owner: nil)
		guard let cellView = _cellView as? EditedStatusTableCellView, let status, let statusHistory, let authorizedAccountProvider = view.window?.windowController as? AuthorizedAccountProviding, let activeInstance =  authorizedAccountProvider.currentInstance, statusHistory.count > row else {
			NSLog("*** Could not prepare view")
			return view
		}
		let currentEdit = statusHistory[row]
		let previousEdit = (highlightDifferences.state == .on && row < statusHistory.count - 1) ? statusHistory[row + 1] : nil
		cellView.set(forStatus: status, displayedStatusEdit: currentEdit, previousStatusEdit: previousEdit, activeInstance: activeInstance)
		return cellView
	}
}
