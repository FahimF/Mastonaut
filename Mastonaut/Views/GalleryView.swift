//
//  GalleryView.swift
//  Mastonaut
//
//  Created by Fahim Farook on 19/01/2023.
//  Copyright © 2023 Bruno Philipe. All rights reserved.
//

import Cocoa
import CoreTootin

protocol AttachmentPresenting: AnyObject {
	func present(attachment: Attachment, from group: AttachmentGroup, senderWindow: NSWindow)
}

class GalleryView: NSScrollView {	
	private let resourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)
	private var images = [AttachmentImageView]()
	@IBOutlet private var imageStack: NSStackView!

	private weak var attachmentPresenter: AttachmentPresenting!

	private var imageViewAttachmentMap = NSMapTable<NSControl, Attachment>(keyOptions: .weakMemory, valueOptions: .structPersonality)

	private let coverView = CoverView(backgroundColor: #colorLiteral(red: 0.05655267835, green: 0.05655267835, blue: 0.05655267835, alpha: 1), textColor: #colorLiteral(red: 0.9999966025, green: 1, blue: 1, alpha: 0.8470588235), message: 🔠("Media Hidden: Click visibility button below to toggle display."))

	private var attachmentGroup: AttachmentGroup!
	private var previewAttachments: [NSView] = []
	private var isMediaHidden = false

	func set(attachments: [Attachment], attachmentPresenter: AttachmentPresenting, mediaHidden: Bool) {
		attachmentGroup = AttachmentGroup(attachments: attachments)
		self.attachmentPresenter = attachmentPresenter
		self.isMediaHidden = mediaHidden
		setup()
	}

	// MARK: - Internal Methods
	@objc
	func presentAttachment(_ sender: Any?) {
		guard let attachmentPresenter = attachmentPresenter else {
			return
		}
		guard let ctrl = sender as? NSControl, let window = ctrl.window else {
			return
		}
		var attachment = images.first?.attachment
		if let att = imageViewAttachmentMap.object(forKey: ctrl) {
			attachment = att
		}
		if let attachment = attachment {
			attachmentPresenter.present(attachment: attachment, from: attachmentGroup, senderWindow: window)
		}
	}

	func setMediaHidden(_ hideMedia: Bool, animated: Bool = true) {
		if hideMedia {
			addCoverView()
		} else {
			coverView.removeFromSuperview()
		}
	}

	func clearGallery() {
		coverView.isHidden = true
		if coverView.superview != nil {
			coverView.removeFromSuperview()
		}
		images.removeAll()
		imageStack.subviews.forEach {
			$0.removeFromSuperview()
		}
	}
	
	// MARK: - Private Methods
	private func setup() {
		images.removeAll()
		if coverView.superview != nil {
			coverView.removeFromSuperview()
		}
		// Add attachments to gallery
		for att in attachmentGroup.attachments {
			let iv = AttachmentImageView()
			iv.attachment = att
			// Set up image view
			iv.cornerRadius = 8
			iv.borderWidth = 1
			iv.borderColor = NSColor.gray.cgColor
			// If we don't have a meta size, we use a placeholder one that closely matches the best size on the UI. This will avoid unecessary layout passes when the image is loaded and set to the image view. Default is: 395 x 200
			let ht = bounds.size.height
			let wd = 395 * (ht / 200)
			var sz = NSSize(width: wd, height: ht)
			if let meta = att.meta, let orig = meta.original, let size = orig.size {
				sz.width = (ht / size.height) * size.width
			}
			iv.defaultContentSize = sz
			iv.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				iv.widthAnchor.constraint(equalToConstant: sz.width),
				iv.heightAnchor.constraint(equalToConstant: sz.height)
			])
			fetchImage(with: att.parsedPreviewUrl ?? att.parsedUrl, fallbackUrl: att.parsedUrl, from: att, placingInto: iv)
			if [.video, .gifv].contains(att.type) {
				let playGlyphView = NSButton(image: #imageLiteral(resourceName: "play_big"), target: self, action: #selector(self.presentAttachment(_:)))
				playGlyphView.bezelStyle = .regularSquare
				playGlyphView.isBordered = false
				playGlyphView.translatesAutoresizingMaskIntoConstraints = false
				iv.addSubview(playGlyphView)
				previewAttachments.append(playGlyphView)
				NSLayoutConstraint.activate([
					iv.leadingAnchor.constraint(equalTo: playGlyphView.leadingAnchor),
					iv.trailingAnchor.constraint(equalTo: playGlyphView.trailingAnchor),
					iv.topAnchor.constraint(equalTo: playGlyphView.topAnchor),
					iv.bottomAnchor.constraint(equalTo: playGlyphView.bottomAnchor),
				])
				imageViewAttachmentMap.setObject(att, forKey: playGlyphView)
			} else {
				imageViewAttachmentMap.setObject(att, forKey: iv)
			}
			// Add image to stack view
			imageStack?.addArrangedSubview(iv)
			images.append(iv)
		}
		setMediaHidden(isMediaHidden)
	}
	
	@objc
	private func toggleMediaVisibility() {
		isMediaHidden.toggle()
		setMediaHidden(isMediaHidden)
	}

	private func addCoverView() {
		guard let parent = superview else { return }
		if coverView.superview != nil {
			coverView.removeFromSuperview()
		}
		parent.addSubview(coverView)
		coverView.target = self
		coverView.action = #selector(toggleMediaVisibility)
		// FIXME: Fast double-clicks can cause the view to re-hide.
		NSLayoutConstraint.activate([
			leftAnchor.constraint(equalTo: coverView.leftAnchor),
			rightAnchor.constraint(equalTo: coverView.rightAnchor),
			topAnchor.constraint(equalTo: coverView.topAnchor),
			bottomAnchor.constraint(equalTo: coverView.bottomAnchor),
		])
	}

	private func fetchImage(with url: URL, fallbackUrl: URL?, from attachment: Attachment, placingInto imageView: AttachmentImageView?) {
		resourcesFetcher.fetchImage(with: url) { [weak imageView, weak self] result in
			guard case let .success(image) = result else {
				DispatchQueue.main.async {
					imageView?.image = NSImage.previewErrorImage
					if let fallbackUrl = fallbackUrl {
						self?.fetchImage(with: fallbackUrl, fallbackUrl: nil, from: attachment, placingInto: imageView)
					}
				}
				return
			}
			let finalImage: NSImage
			if image.pixelSize.area > NSSize(width: 1024, height: 1024).area {
				finalImage = image.resizedImage(withSize: NSSize(width: 1024, height: 1024))
			} else {
				finalImage = image
			}
			DispatchQueue.main.async {
				guard let self = self else {
					return
				}
				self.attachmentGroup.set(preview: finalImage, for: attachment)
				imageView?.image = finalImage
				imageView?.toolTip = attachment.description
				imageView?.setAccessibilityLabel(attachment.description)
				imageView?.target = self
				imageView?.action = #selector(GalleryView.presentAttachment(_:))
			}
		}
	}
}
