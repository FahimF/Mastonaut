//
//  BaseComposerTextView.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 15.09.19.
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

@IBDesignable
open class BaseComposerTextView: SuggestionTextView {
	@IBInspectable
	public var insertDoubleNewLines: Bool = false

	@IBOutlet
	public var submitControl: NSControl? = nil

	override public func insertNewline(_ sender: Any?) {
		guard suggestionWindowController.isWindowVisible == false else {
			insertCurrentlySelectedSuggestion()
			return
		}

		if insertDoubleNewLines {
			super.insertNewline(sender)
			super.insertNewline(sender)
		} else {
			super.insertNewline(sender)
		}
	}

	public func insertAttributedString(_ attributedString: NSAttributedString) {
		guard let textStorage = textStorage else { return }

		let selectedRange = self.selectedRange()

		if let undoManager = undoManager {
			let undoRange = NSMakeRange(selectedRange.location, attributedString.length)
			let undoString = textStorage.attributedSubstring(from: selectedRange)
			undoManager.registerUndo(withTarget: textStorage) {
				textStorage in textStorage.replaceCharacters(in: undoRange, with: undoString)
			}
		}

		textStorage.replaceCharacters(in: selectedRange, with: applyTypingAttributes(to: attributedString))
		didChangeText()
	}

	public func applyTypingAttributes(to string: NSAttributedString) -> NSAttributedString {
		let formattedString = string.mutableCopy() as! NSMutableAttributedString
		formattedString.addAttributes(typingAttributes, range: NSMakeRange(0, string.length))
		return formattedString
	}
}
