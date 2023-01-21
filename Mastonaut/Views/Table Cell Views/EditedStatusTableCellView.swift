//
//  EditedStatusTableCellView.swift
//  Mastonaut
//
//  Created by Sören Kuklau on 07.01.23.
//  Copyright © 2023 Bruno Philipe. All rights reserved.
//

import CoreTootin
import Foundation
import Sdifft

class EditedStatusTableCellView: NSTableCellView {
	@IBOutlet private unowned var authorNameButton: NSButton!
	@IBOutlet private unowned var authorAccountLabel: NSTextField!
	@IBOutlet private unowned var statusLabel: AttributedLabel!
	@IBOutlet private unowned var timeLabel: NSTextField!

	@IBOutlet var contentWarningContainer: BorderView!
	@IBOutlet var contentWarningLabel: AttributedLabel!

	override func awakeFromNib() {
		super.awakeFromNib()

		/// BUG: outlets will be `nil` if window has been restored (e.g., after app relaunch) (see #88)
		if let timeLabel {
			timeLabel.formatter = RelativeDateFormatter.shared
		}
	}

	@objc internal private(set) dynamic
	var cellModel: StatusEditCellModel?

	func set(forStatus status: Status, displayedStatusEdit statusEdit: StatusEdit, previousStatusEdit: StatusEdit?, activeInstance: Instance) {
		let cellModel = StatusEditCellModel(statusEdit: statusEdit)
		self.cellModel = cellModel

		authorNameButton.set(stringValue: status.authorName,
		                     applyingAttributes: EditedStatusTableCellView._authorLabelAttributes,
		                     applyingEmojis: status.account.cacheableEmojis)

		authorAccountLabel.stringValue = status.account.uri(in: activeInstance)
		timeLabel.objectValue = statusEdit.createdAt
		timeLabel.toolTip = DateFormatter.longDateFormatter.string(from: statusEdit.createdAt)

		contentWarningContainer.isHidden = true

		// https://github.com/chucker/Mastonaut/issues/79 unclear why needed (otherwise set to pink)
		contentWarningLabel.backgroundColor = NSColor.clear
		statusLabel.backgroundColor = NSColor.clear

		if let previousStatusEdit {
			let previousContent = previousStatusEdit.attributedContent.string
			let content = statusEdit.attributedContent.string

			statusLabel.attributedStringValue = NSAttributedString(source: previousContent,
			                                                       target: content,
			                                                       attributes: EditedStatusTableCellView._diffAttributes)
		}
		else {
			statusLabel.stringValue = statusEdit.attributedContent.string
		}
	}

	private static let _diffAttributes: DiffAttributes =
		.init(
			insert: [.backgroundColor: NSColor.green],
			delete: [.backgroundColor: NSColor.red],
			same: [.backgroundColor: NSColor.white]
		)

	private static let _authorLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 14, weight: .semibold)
	]

	private static let _statusLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: 14),
		.underlineStyle: NSNumber(value: 0) // <-- This is a hack to prevent the label's contents from shifting
		// vertically when clicked.
	]
}
