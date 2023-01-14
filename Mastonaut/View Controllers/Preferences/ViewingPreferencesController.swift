//
//  ViewingPreferencesController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 16.02.19.
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

class ViewingPreferencesController: NSViewController {
	@IBOutlet private var normalTextSizeLabel: NSTextField!
	@IBOutlet private var normalTextSizeSlider: NSSlider!
	
	@IBOutlet private var sensitiveMediaHideSensitiveButton: NSButton!
	@IBOutlet private var sensitiveMediaAlwaysRevealButton: NSButton!
	@IBOutlet private var sensitiveMediaAlwaysHideButton: NSButton!

	@IBOutlet private var spoilerStatusHideAllContentButton: NSButton!
	@IBOutlet private var spoilerStatusRevealTextButton: NSButton!
	@IBOutlet private var spoilerStatusRevealAllButton: NSButton!

	@IBOutlet private var autoplayVideosButton: NSButton!

	private var preferenceObservers: [AnyObject] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		normalTextSizeSlider.intValue = Int32(MastonautPreferences.instance.normalTextSize)
		normalTextSizeLabel.stringValue = "Normal text size (\(normalTextSizeSlider.stringValue)px):"
		let sensitiveMediaButtonMap: [MastonautPreferences.MediaDisplayMode: NSButton] = [
			.alwaysHide: sensitiveMediaAlwaysHideButton,
			.hideSensitiveMedia: sensitiveMediaHideSensitiveButton,
			.alwaysReveal: sensitiveMediaAlwaysRevealButton,
		]
		preferenceObservers.append(PreferenceEnumRadioObserver(preference: \MastonautPreferences.mediaDisplayMode, buttonMap: sensitiveMediaButtonMap))
		let spoilerStatusButtonMap: [MastonautPreferences.SpoilerDisplayMode: NSButton] = [
			.alwaysHide: spoilerStatusHideAllContentButton,
			.hideMedia: spoilerStatusRevealTextButton,
			.alwaysReveal: spoilerStatusRevealAllButton,
		]
		preferenceObservers.append(PreferenceEnumRadioObserver(preference: \MastonautPreferences.spoilerDisplayMode, buttonMap: spoilerStatusButtonMap))
		preferenceObservers.append(PreferenceCheckboxObserver(preference: \.autoplayVideos, checkbox: autoplayVideosButton))
	}
	
	@IBAction func normalTextSizeChanged(sender: AnyObject) {
		normalTextSizeLabel.stringValue = "Normal text size (\(normalTextSizeSlider.stringValue)px):"
		MastonautPreferences.instance.normalTextSize = CGFloat(normalTextSizeSlider.intValue)
	}
}
