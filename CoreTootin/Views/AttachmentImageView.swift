//
//  AttachmentImageView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.01.19.
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

@IBDesignable
public class AttachmentImageView: NSControl {
	public var attachment: Attachment!
	
	private lazy var clickGestureRecognizer: NSClickGestureRecognizer = {
		let recognizer = NSClickGestureRecognizer()
		recognizer.numberOfClicksRequired = 1
		recognizer.target = self
		recognizer.action = #selector(AttachmentImageView.gestureRecognizer(_:))
		return recognizer
	}()

	@IBInspectable
	public var cornerRadius: CGFloat = 0.0 {
		didSet {
			if let layer = layer {
				layer.cornerRadius = cornerRadius
			}
		}
	}

	@IBInspectable
	public var borderWidth: CGFloat = 0.0 {
		didSet {
			if let layer = layer {
				layer.borderWidth = borderWidth
			}
		}
	}

	@IBInspectable
	public var borderColor: CGColor = NSColor.clear.cgColor {
		didSet {
			if let layer = layer {
				layer.borderColor = borderColor
			}
		}
	}

	@IBInspectable
	public var exposureAdjust: CGFloat = 0 {
		didSet {
			applyExposureFilterIfNecessary()
		}
	}

	@IBInspectable
	public var image: NSImage? {
		didSet {
			needsDisplay = true
			if defaultContentSize == nil, superview != nil {
				// There's no need to invalidate the intrinsic content size if we are overriding it, or if we're not attached yet.
				invalidateIntrinsicContentSize()
			}
		}
	}

	/// Use this value as the intrinsicContentSize.
	///
	/// Useful if the size of the image is known before it is fetched from a remote location, for example.
	public var defaultContentSize: NSSize? = nil {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}

	override public var wantsUpdateLayer: Bool {
		return true
	}

	override public var intrinsicContentSize: NSSize {
		return defaultContentSize ?? image?.size ?? .zero
	}

	override public init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setup()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}

	private func setup() {
		addGestureRecognizer(clickGestureRecognizer)
	}

	override public func updateLayer() {
		guard let layer = layer else {
			assertionFailure()
			return
		}
		guard let image = image else {
			layer.contents = nil
			return
		}
		layer.contentsGravity = .resizeAspect
		layer.contents = image.layerContents(forContentsScale: window?.backingScaleFactor ?? 1.0)
		layer.masksToBounds = true
		layer.cornerRadius = cornerRadius
		layer.borderWidth = borderWidth
		layer.borderColor = borderColor
		applyExposureFilterIfNecessary()
	}

	// MARK: - Private Methods
	@objc private func gestureRecognizer(_: Any?) {
		sendAction(action, to: target)
	}

	private func applyExposureFilterIfNecessary() {
		if exposureAdjust != 0 {
			layer?.filters = [CIFilter(name: "CIExposureAdjust", parameters: ["inputEV": exposureAdjust])!]
		} else {
			layer?.filters = nil
		}
	}	
}
