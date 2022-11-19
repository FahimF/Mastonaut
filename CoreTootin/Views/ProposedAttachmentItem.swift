//
//  ProposedAttachmentItem.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.02.19.
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

public class ProposedAttachmentItem: NSCollectionViewItem {
	@IBOutlet private var indicatorView: NSImageView!

	override public func awakeFromNib() {
		super.awakeFromNib()

		indicatorView.unregisterDraggedTypes()
	}

	override public var nibBundle: Bundle? {
		return Bundle(for: ProposedAttachmentItem.self)
	}
}
