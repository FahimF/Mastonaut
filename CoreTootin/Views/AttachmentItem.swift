//
//  AttachmentItem.swift
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

public class AttachmentItem: NSCollectionViewItem {
	var descriptionButtonAction: (() -> Void)?
	var removeButtonAction: (() -> Void)?

	@IBOutlet private var itemImageView: AttachmentImageView!
	@IBOutlet private var itemDetailIcon: NSImageView!
	@IBOutlet private var itemDetailLabel: NSTextField!
	@IBOutlet private var itemDetailContainer: NSView!
	@IBOutlet private var failureIndicatorImageView: NSImageView!

	@IBOutlet private var showDescriptionEditorButton: NSButton!

	@IBOutlet private var progressIndicator: NSProgressIndicator!
	@IBOutlet private var descriptionProgressIndicator: NSProgressIndicator!

	var displayedItemHashValue: Int?

	override public var nibBundle: Bundle? {
		return Bundle(for: AttachmentItem.self)
	}

	var hasFailure: Bool = false {
		didSet { failureIndicatorImageView.isHidden = !hasFailure }
	}

	var isPendingSetDescription: Bool = false {
		didSet {
			if isPendingSetDescription {
				descriptionProgressIndicator.startAnimation(nil)
				showDescriptionEditorButton.isEnabled = false
			} else {
				descriptionProgressIndicator.stopAnimation(nil)
				showDescriptionEditorButton.isEnabled = true
			}
		}
	}

	override public func awakeFromNib() {
		super.awakeFromNib()
		itemImageView.unregisterDraggedTypes()
		failureIndicatorImageView.unregisterDraggedTypes()
		itemDetailIcon.unregisterDraggedTypes()
	}

	func set(progressIndicatorState state: UploadState) {
		switch state {
		case .waitingToUpload:
			progressIndicator.isIndeterminate = true
			progressIndicator.isHidden = false
			progressIndicator.startAnimation(nil)

		case let .uploading(progress):
			progressIndicator.stopAnimation(nil)
			progressIndicator.isIndeterminate = false
			progressIndicator.isHidden = false
			progressIndicator.doubleValue = progress * 100

		case .uploaded:
			progressIndicator.stopAnimation(nil)
			progressIndicator.isIndeterminate = false
			progressIndicator.isHidden = true
		}
	}

	func set(itemMetadata: Metadata?) {
		switch itemMetadata {
		case let .some(.picture(byteCount)):
			detailIcon = Bundle(for: AttachmentItem.self).image(forResource: "tiny_camera")
			detail = ByteCountFormatter().string(fromByteCount: byteCount)

		case let .some(.movie(duration)):
			detailIcon = Bundle(for: AttachmentItem.self).image(forResource: "tiny_film")
			detail = duration.formattedStringValue

		default:
			detailIcon = nil
			detail = nil
		}
	}

	var image: NSImage? {
		get { return itemImageView.image }
		set { itemImageView.image = newValue }
	}

	var detail: String? {
		get { return itemDetailLabel.stringValue }
		set {
			if let detail = newValue {
				itemDetailLabel.stringValue = detail
				itemDetailContainer.isHidden = false
			} else {
				itemDetailLabel.stringValue = ""
				itemDetailContainer.isHidden = true
			}
		}
	}

	var detailIcon: NSImage? {
		get { return itemDetailIcon.image }
		set { itemDetailIcon.image = newValue }
	}

	@IBAction private func descriptionButtonClicked(_: Any?) {
		descriptionButtonAction?()
	}

	@IBAction private func removeButtonClicked(_: Any?) {
		removeButtonAction?()
	}

	enum UploadState {
		case waitingToUpload
		case uploading(progress: Double)
		case uploaded
	}
}

class AttachmentItemImageView: NSImageView {
	@IBInspectable
	var cornerRadius: CGFloat = 0.0 {
		didSet {
			if let layer = layer {
				layer.cornerRadius = cornerRadius
			}
		}
	}
}

class ShowOnHoverView: HoverView {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		alphaValue = 0.001
	}

	override func mouseEntered(with event: NSEvent) {
		super.mouseEntered(with: event)
		animator().alphaValue = 1.0
	}

	override func mouseExited(with event: NSEvent) {
		super.mouseExited(with: event)
		animator().alphaValue = 0.001
	}
}
