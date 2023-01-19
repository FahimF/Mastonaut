//
//  CardView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.01.19.
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

class CardView: BorderView {
	var clickHandler: (() -> Void)?

	@IBOutlet private unowned var imageView: AttachmentImageView!
	@IBOutlet private unowned var titleLabel: NSTextField!
	@IBOutlet private unowned var urlLabel: NSTextField!

	var backgroundStyle = NSView.BackgroundStyle.normal {
		didSet {
			let emphasized = backgroundStyle == .emphasized
			let effectiveColor: NSColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
			borderColor = effectiveColor
			titleLabel.textColor = effectiveColor
			urlLabel.textColor = effectiveColor
		}
	}

	@IBAction private func clickedCardButton(_: Any?) {
		if let handler = clickHandler {
			handler()
		}
	}
	
	func set(card: Card, statusID: String?) {
		let cardUrl = card.url
		titleLabel.stringValue = card.title
		urlLabel.stringValue = cardUrl.host ?? ""
		guard card.imageUrl != nil, let currentlyDisplayedStatusId = statusID else {
			imageView.image = nil
			return
		}
		imageView.image = #imageLiteral(resourceName: "missing")
		card.fetchImage { [weak self] image in
			DispatchQueue.main.async {
				guard statusID == currentlyDisplayedStatusId else {
					return
				}
				self?.imageView.image = image
			}
		}
	}
}
