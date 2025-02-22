//
//  AnimatableEmojiCell.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 19.01.19.
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

class AnimatableEmojiCell: NSTextAttachmentCell {
	private let referenceSize: NSSize?
	private let referenceSpacing: CGFloat?
	private let lineHasMoreCharacters: Bool
	private let lineHasEmoji: Bool

	private var emojiImageSize: NSSize?

	@objc weak var containerView: NSView?
	@objc weak var imageView: AnimatedImageView?
	@objc var emojiData: Data?
	@objc var lastImageViewRect: NSRect = .zero
	@objc var toolTip: String?

	init(emojiLoader: (@escaping (Data?) -> Void) -> Void,
	     lineHasMoreCharacters: Bool, lineHasEmoji: Bool,
	     font: NSFont? = nil)
	{
		self.lineHasMoreCharacters = lineHasMoreCharacters
		self.lineHasEmoji = lineHasEmoji

		if let font = font {
			let referenceHeight = boundingRect(for: "💾", using: font).height
			referenceSize = CGSize(width: referenceHeight, height: referenceHeight)
			referenceSpacing = boundingRect(for: "i", using: font).width
		} else {
			referenceSize = nil
			referenceSpacing = nil
		}

		super.init()

		font.map { self.font = $0 }

		emojiLoader {
			[weak self] emojiData in

			DispatchQueue.main.async {
				if let data = emojiData, let self = self {
					self.setImage(from: data)
				}
			}
		}
	}

	@available(*, unavailable)
	required init(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setImage(from data: Data) {
		guard let image = NSImage(data: data), image.size.area > 0 else {
			return
		}

		emojiImageSize = image.pixelSize
		emojiData = data

		if let animatedImageView = imageView {
			animatedImageView.setAnimatedImage(from: data)
		}

		informContainerViewOfUpdatedContent()
	}

	internal func informContainerViewOfUpdatedContent() {
		containerView?.invalidateIntrinsicContentSize()
		containerView?.needsDisplay = true
	}

	override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
		if #available(OSX 12.0, *) {
			let spacing = referenceSpacing ?? round(cellFrame.height * 0.05)
			let offsetRect = cellFrame.insetBy(left: spacing / 2, right: 0, top: 0, bottom: 0)
			imageView?.frame = offsetRect
			lastImageViewRect = offsetRect
		}
		super.draw(withFrame: cellFrame, in: controlView)
	}

	override func cellFrame(for textContainer: NSTextContainer,
	                        proposedLineFragment lineFragment: NSRect,
	                        glyphPosition position: NSPoint,
	                        characterIndex _: Int) -> NSRect
	{
		let textView = textContainer.textView
		let inset: NSSize = textView?.textContainerInset ?? .zero

		let bounds = NSRect(x: ceil(position.x) + inset.width,
		                    y: font?.descender ?? 0 + inset.height,
		                    width: referenceSize?.width ?? lineFragment.width,
		                    height: referenceSize?.height ?? lineFragment.height)

		let rect = fittedDrawRect(forBounds: bounds)

		attachment?.bounds = rect

		if #available(OSX 12.0, *) {} else if let imageView = imageView {
			let spacing = referenceSpacing ?? round(bounds.height * 0.05)
			var offsetRect = rect
			offsetRect.size.width -= spacing

			offsetRect.origin.y = inset.height + position.y

			if textView != nil {
				offsetRect.origin.x += textContainer.lineFragmentPadding
				offsetRect.origin.x -= spacing
			} else {
				offsetRect.origin.x += spacing

				// FIXME: Find out why this offset varies from 10.14 to 10.15
				if #available(OSX 10.15, *) {} else {
					offsetRect.origin.y -= round(font?.descender ?? 0)
				}
			}

			imageView.frame = offsetRect
			lastImageViewRect = offsetRect
		}

		return rect
	}

	private func fittedDrawRect(forBounds rect: NSRect) -> NSRect {
		let spacing = referenceSpacing ?? round(rect.height * 0.05)
		let emojiSize = emojiImageSize ?? referenceSize ?? rect.size
		return NSRect(x: rect.origin.x + spacing,
		              y: rect.origin.y,
		              width: rect.height * emojiSize.ratio + spacing,
		              height: rect.height)
	}
}

private func boundingRect(for string: String, using font: NSFont) -> CGSize {
	let referenceString = string as NSString
	return referenceString.boundingRect(with: NSSize(width: 100, height: 100),
	                                    options: [.usesFontLeading,
	                                              .usesLineFragmentOrigin,
	                                              .usesDeviceMetrics],
	                                    attributes: [.font: font]).size
}
