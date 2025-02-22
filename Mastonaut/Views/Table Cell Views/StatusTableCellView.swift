//
//  StatusTableCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 26.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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
import Sdifft

@IBDesignable
class StatusTableCellView: MastonautTableCellView, StatusDisplaying, StatusInteractionPresenter {
	@IBOutlet private unowned var authorNameButton: NSButton!
	@IBOutlet private unowned var authorAccountLabel: NSTextField!
	@IBOutlet private unowned var statusLabel: AttributedLabel!
	@IBOutlet private unowned var fullContentDisclosureView: NSView?
	@IBOutlet private unowned var timeLabel: NSTextField!
	@IBOutlet private unowned var editInfoContainer: NSStackView!
	@IBOutlet private unowned var editedTimeLabel: NSTextField!
	@IBOutlet private unowned var mainContentStackView: NSStackView!

	@IBOutlet private unowned var contentWarningContainer: BorderView!
	@IBOutlet private unowned var contentWarningLabel: AttributedLabel!

	@IBOutlet unowned var replyButton: NSButton!
	@IBOutlet unowned var replyCount: NSTextField!
	@IBOutlet unowned var reblogButton: NSButton!
	@IBOutlet unowned var reblogCount: NSTextField!
	@IBOutlet unowned var favoriteButton: NSButton!
	@IBOutlet unowned var favouriteCount: NSTextField!
	@IBOutlet unowned var bookmarkButton: NSButton!
	@IBOutlet unowned var warningButton: NSButton!
	@IBOutlet unowned var sensitiveContentButton: NSButton!

	@IBOutlet private unowned var contextButton: NSButton?
	@IBOutlet private unowned var contextImageView: NSImageView?

	@IBOutlet private unowned var vwGallery: GalleryView!
	@IBOutlet private unowned var infoLabel: NSTextField!

	@IBOutlet private unowned var cardContainerView: CardView!
	private var pollViewController: PollViewController?

	private(set) var hasMedia = false
	private(set) var hasSensitiveMedia = false
	private(set) var hasSpoiler = false

	var isContentHidden: Bool {
		return warningButton.state == .off
	}

	var isMediaHidden: Bool {
		return sensitiveContentButton.state == .off
	}

	private var userDidInteractWithVisibilityControls = false

	private weak var tableViewWidthConstraint: NSLayoutConstraint?

	@objc internal private(set) dynamic
	var cellModel: StatusCellModel? {
		didSet { updateAccessibilityAttributes() }
	}

	private lazy var spoilerCoverView: NSView = {
		let coverView = CoverView(backgroundColor: NSColor(named: "SpoilerCoverBackground")!, message: 🔠("Content Hidden: Click warning button below to toggle display."))
		coverView.target = self
		coverView.action = #selector(toggleContentVisibility)
		return coverView
	}()

	private static let _authorLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: MastonautPreferences.instance.normalTextSize, weight: .semibold),
	]

	private static let _statusLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: MastonautPreferences.instance.normalTextSize),
		.underlineStyle: NSNumber(value: 0), // <-- This is a hack to prevent the label's contents from shifting
		// vertically when clicked.
	]

	private static let _statusLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.safeControlTintColor,
		.font: NSFont.systemFont(ofSize: MastonautPreferences.instance.normalTextSize, weight: .medium),
		.underlineStyle: NSNumber(value: 1),
	]

	private static let _contextLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 12, weight: .medium),
	]

	internal func authorLabelAttributes() -> [NSAttributedString.Key: AnyObject] {
		return StatusTableCellView._authorLabelAttributes
	}

	internal func statusLabelAttributes() -> [NSAttributedString.Key: AnyObject] {
		return StatusTableCellView._statusLabelAttributes
	}

	internal func statusLabelLinkAttributes() -> [NSAttributedString.Key: AnyObject] {
		return StatusTableCellView._statusLabelLinkAttributes
	}

	internal func contextLabelAttributes() -> [NSAttributedString.Key: AnyObject] {
		return StatusTableCellView._contextLabelAttributes
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		timeLabel.formatter = RelativeDateFormatter.shared
		statusLabel.linkTextAttributes = statusLabelLinkAttributes()
		cardContainerView.clickHandler = { [weak self] in
			self?.cellModel?.openCardLink()
		}
	}

	override var backgroundStyle: NSView.BackgroundStyle {
		didSet {
			let emphasized = backgroundStyle == .emphasized
			statusLabel.isEmphasized = emphasized
			contentWarningLabel.isEmphasized = emphasized
			let effectiveColor: NSColor = emphasized ? .alternateSelectedControlTextColor : .secondaryLabelColor
			authorAccountLabel.textColor = effectiveColor
			timeLabel.textColor = effectiveColor
		}
	}

	func set(displayedStatus status: Status, poll: Poll?, attachmentPresenter: AttachmentPresenting, interactionHandler: StatusInteractionHandling, activeInstance: Instance) {
		let cellModel = StatusCellModel(status: status, interactionHandler: interactionHandler)
		self.cellModel = cellModel

		statusLabel.linkHandler = cellModel
		contentWarningLabel.linkHandler = cellModel
		authorNameButton.set(stringValue: cellModel.visibleStatus.authorName, applyingAttributes: authorLabelAttributes(), applyingEmojis: cellModel.visibleStatus.account.cacheableEmojis)
		contextButton.map {
			cellModel.setupContextButton($0, attributes: contextLabelAttributes())
		}

		authorAccountLabel.stringValue = cellModel.visibleStatus.account.uri(in: activeInstance)
		timeLabel.objectValue = cellModel.visibleStatus.createdAt
		timeLabel.toolTip = DateFormatter.longDateFormatter.string(from: cellModel.visibleStatus.createdAt)
		
		// Set counts
		replyCount.stringValue = "\(status.repliesCount)"
		reblogCount.stringValue = "\(status.reblogsCount)"
		favouriteCount.stringValue = "\(status.favouritesCount)"

		if let editedAt = cellModel.visibleStatus.editedAt {
			editInfoContainer.isHidden = false
			editedTimeLabel.objectValue = "Edited \(RelativeDateFormatter.shared.string(from: editedAt))"
			editedTimeLabel.toolTip = DateFormatter.longDateFormatter.string(from: editedAt)
		} else {
			editInfoContainer.isHidden = true
		}

		let attributedStatus = cellModel.visibleStatus.attributedContent

		// We test the attributed string since it might produce a visually empty result if the contents were simply the same link URL as the link on a card, for example.
		if attributedStatus.isEmpty, status.mediaAttachments.isEmpty == false {
			statusLabel.stringValue = ""
			statusLabel.toolTip = nil
			statusLabel.isHidden = true
			fullContentDisclosureView?.isHidden = true
		} else if fullContentDisclosureView != nil, attributedStatus.length > 500 {
			let truncatedString = attributedStatus.attributedSubstring(from: NSMakeRange(0, 500)).mutableCopy() as! NSMutableAttributedString
			truncatedString.append(NSAttributedString(string: "…"))

			statusLabel.isHidden = false
			fullContentDisclosureView?.isHidden = false
			statusLabel.set(attributedStringValue: truncatedString, applyingAttributes: statusLabelAttributes(), applyingEmojis: cellModel.visibleStatus.cacheableEmojis)
		} else {
			statusLabel.isHidden = false
			fullContentDisclosureView?.isHidden = true
			statusLabel.set(attributedStringValue: attributedStatus, applyingAttributes: statusLabelAttributes(), applyingEmojis: cellModel.visibleStatus.cacheableEmojis)
		}
		statusLabel.isEnabled = true
		if cellModel.visibleStatus.spoilerText.isEmpty {
			contentWarningContainer.isHidden = true
			warningButton.isHidden = true
			set(displayedCard: cellModel.visibleStatus.card)
			hasSpoiler = false
			contentWarningLabel.stringValue = ""
			contentWarningLabel.toolTip = nil
		} else {
			cardContainerView.isHidden = true
			warningButton.isHidden = false
			hasSpoiler = true
			contentWarningLabel.set(attributedStringValue: cellModel.visibleStatus.attributedSpoiler, applyingAttributes: statusLabelAttributes(), applyingEmojis: cellModel.visibleStatus.cacheableEmojis)
			installSpoilerCover()
			contentWarningContainer.isHidden = false
		}
		hasMedia = status.mediaAttachments.count > 0
		hasSensitiveMedia = status.sensitive == true
		setUpInteractions(status: cellModel.visibleStatus)
		setupAttachmentsContainerView(for: cellModel.visibleStatus, poll: poll, attachmentPresenter: attachmentPresenter)
	}

	func updateAccessibilityAttributes() {
		guard let model = cellModel else {
			setAccessibilityLabel("")
			return
		}

		var components = [String]()

		components.append(model.visibleStatus.authorName)
		components.append(model.visibleStatus.attributedContent.strippingEmojiAttachments(insertJoinersBetweenEmojis: false))
		components.append(RelativeDateFormatter.shared.string(from: model.visibleStatus.createdAt))
		components.append(model.visibleStatus.authorAccount)

		if model.visibleStatus.id != model.status.id {
			let rebloggedAt = RelativeDateFormatter.shared.string(from: model.status.createdAt)
			components.append("retooted by \(model.status.authorName) \(rebloggedAt)")
			components.append(model.status.authorAccount)
		}

		setAccessibilityLabel("Post")
		setAccessibilityElement(true)
		setAccessibilityTitle(components.joined(separator: ", "))
	}

	func set(updatedPoll: Poll) {
		pollViewController?.set(poll: updatedPoll)
	}

	func setHasActivePollTask(_ hasTask: Bool) {
		pollViewController?.setHasActiveReloadTask(hasTask)
	}

	func updateContentsVisibility() {
		guard userDidInteractWithVisibilityControls == false else { return }
		if hasSpoiler {
			switch Preferences.spoilerDisplayMode {
			case .alwaysHide:
				setContentHidden(true)
				setMediaHidden(true)

			case .hideMedia:
				setContentHidden(false)
				setMediaHidden(true)

			case .alwaysReveal:
				setContentHidden(false)
				setMediaHidden(false)
			}
		} else if hasMedia {
			switch Preferences.mediaDisplayMode {
			case .alwaysHide:
				setMediaHidden(true)

			case .hideSensitiveMedia:
				setMediaHidden(hasSensitiveMedia)

			case .alwaysReveal:
				setMediaHidden(false)
			}
		}
	}

	private func setupAttachmentsContainerView(for status: Status, poll: Poll?, attachmentPresenter: AttachmentPresenting) {
		vwGallery.clearGallery()
		infoLabel.isHidden = true
		if status.mediaAttachments.count > 0 {
			vwGallery.isHidden = false
			var hidden = false
			if Preferences.mediaDisplayMode == .alwaysHide || Preferences.mediaDisplayMode == .hideSensitiveMedia {
				hidden = true
			}
			hidden = hidden && status.sensitive ?? false
			vwGallery.set(attachments: status.mediaAttachments, attachmentPresenter: attachmentPresenter, mediaHidden: hidden)
			// Show/hide label
			let cnt = status.mediaAttachments.count
			if cnt > 1 {
				infoLabel.isHidden = false
				infoLabel.stringValue = "\(cnt) images. Scroll to see all."
			}
		} else if let poll = poll ?? status.poll {
			vwGallery.isHidden = true
			let pollViewController = PollViewController()
			pollViewController.set(poll: poll)
			pollViewController.delegate = cellModel
			let pollView = pollViewController.view
			mainContentStackView.addArrangedSubview(pollView)
			mainContentStackView.widthAnchor.constraint(equalTo: pollView.widthAnchor).isActive = true
			self.pollViewController = pollViewController
		} else {
			vwGallery.isHidden = true
		}
	}

	internal func set(displayedCard card: Card?) {
		guard let card = card else {
			cardContainerView.isHidden = true
			return
		}
		cardContainerView.isHidden = false
		cardContainerView.set(card: card, statusID: cellModel?.status.id)
	}

	func setContentLabelsSelectable(_ selectable: Bool) {
		contentWarningLabel.selectableAfterFirstClick = selectable
		statusLabel.selectableAfterFirstClick = selectable
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		cellModel = nil
		statusLabel.alphaValue = 1
		userDidInteractWithVisibilityControls = false
		pollViewController?.view.removeFromSuperview()
		pollViewController = nil
		removeSpoilerCover()
	}

	@IBAction func viewHistoryClicked(_ sender: NSButton) {
		guard let status = cellModel?.visibleStatus, let interactionHandler = cellModel?.interactionHandler else { return }
		let handler = cellModel?.interactionHandler
		interactionHandler.fetchEditHistory(for: status.id) {
			success in DispatchQueue.main.async {
				guard let edits = success else { return }
				interactionHandler.showStatusEdits(status: status, edits: edits)
			}
		}
	}

	@IBAction private func interactionButtonClicked(_ sender: NSButton) {
		switch (sender, sender.state) {
		case (favoriteButton, .on):
			cellModel?.handle(interaction: .favorite)

		case (favoriteButton, .off):
			cellModel?.handle(interaction: .unfavorite)

		case (bookmarkButton, .on):
			cellModel?.handle(interaction: .bookmark)

		case (bookmarkButton, .off):
			cellModel?.handle(interaction: .unbookmark)

		case (reblogButton, .on):
			cellModel?.handle(interaction: .reblog)

		case (reblogButton, .off):
			cellModel?.handle(interaction: .unreblog)

		case (replyButton, _):
			cellModel?.handle(interaction: .reply)

		case (warningButton, .on):
			userDidInteractWithVisibilityControls = true
			setContentHidden(false)
			setMediaHidden(false)

		case (warningButton, .off):
			userDidInteractWithVisibilityControls = true
			setContentHidden(true)
			setMediaHidden(true)

		case (sensitiveContentButton, .on):
			userDidInteractWithVisibilityControls = true
			setMediaHidden(false)

		case (sensitiveContentButton, .off):
			userDidInteractWithVisibilityControls = true
			setMediaHidden(true)

		default: break
		}
	}

	@objc func toggleContentVisibility() {
		guard hasSpoiler else { return }
		setContentHidden(!isContentHidden)
		if isMediaHidden, !isContentHidden {
			setMediaHidden(isContentHidden)
		}
		userDidInteractWithVisibilityControls = true
	}

	func toggleMediaVisibility() {
		guard hasMedia else { return }
		setMediaHidden(!isMediaHidden)
		userDidInteractWithVisibilityControls = true
	}

	@IBAction func showAuthor(_: Any) {
		cellModel?.showAuthor()
	}

	@IBAction func showAgent(_: Any) {
		cellModel?.showAgent()
	}

	@IBAction func showTootDetails(_: Any) {
		cellModel?.showTootDetails()
	}

	@IBAction func showContextDetails(_: Any) {
		cellModel?.showContextDetails()
	}

	func setMediaHidden(_ hideMedia: Bool) {
		vwGallery.setMediaHidden(hideMedia)
		sensitiveContentButton.state = hideMedia ? .off : .on
	}

	func setContentHidden(_ hideContent: Bool) {
		let coverView = spoilerCoverView
//		let hasSensitiveMedia = attachmentViewController?.sensitiveMedia == true
		warningButton.state = hideContent ? .off : .on
		statusLabel.animator().alphaValue = hideContent ? 0 : 1
		statusLabel.setAccessibilityEnabled(!hideContent)
		vwGallery.animator().alphaValue = hideContent ? 0 : 1
		vwGallery.setAccessibilityEnabled(!hideContent)
		coverView.setHidden(!hideContent, animated: true)
		statusLabel.isEnabled = !hideContent
		if hasSensitiveMedia {
			sensitiveContentButton.setHidden(hideContent, animated: true)
		}
	}

	internal func installSpoilerCover() {
		removeSpoilerCover()
		let spolierCover = spoilerCoverView
		addSubview(spolierCover)
		let spacing = mainContentStackView.spacing
		NSLayoutConstraint.activate([
			spolierCover.topAnchor.constraint(equalTo: contentWarningContainer.bottomAnchor, constant: spacing),
			spolierCover.bottomAnchor.constraint(equalTo: mainContentStackView.bottomAnchor, constant: 2),
			spolierCover.leftAnchor.constraint(equalTo: mainContentStackView.leftAnchor),
			spolierCover.rightAnchor.constraint(equalTo: mainContentStackView.rightAnchor),
		])
	}

	internal func removeSpoilerCover() {
		spoilerCoverView.removeFromSuperview()
	}
}

extension StatusTableCellView: MediaPresenting {
	func makePresentableMediaVisible() {
		vwGallery.presentAttachment(nil)
	}
}

extension StatusTableCellView: RichTextCapable {
	func set(shouldDisplayAnimatedContents animates: Bool) {
		authorNameButton.animatedEmojiImageViews?.forEach { $0.animates = animates }
		contextButton?.animatedEmojiImageViews?.forEach { $0.animates = animates }
		statusLabel.animatedEmojiImageViews?.forEach { $0.animates = animates }
		contentWarningLabel.animatedEmojiImageViews?.forEach { $0.animates = animates }
	}
}
