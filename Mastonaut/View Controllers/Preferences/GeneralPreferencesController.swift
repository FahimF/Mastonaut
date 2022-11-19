//
//  GeneralPreferencesViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 12.05.19.
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

import CoreTootin
import Foundation

class GeneralPreferencesController: NSViewController {
	@IBOutlet private var timelinesResizeExpandFirstButton: NSButton!
	@IBOutlet private var timelinesResizeShrinkFirstButton: NSButton!

	@IBOutlet private var newWindowAccountModeAskButton: NSButton!
	@IBOutlet private var newWindowAccountModePickFirstOneButton: NSButton!

	private var preferenceObservers: [AnyObject] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		let timelinesResizeModeButtonMap: [MastonautPreferences.TimelinesResizeMode: NSButton] = [
			.expandWindowFirst: timelinesResizeExpandFirstButton,
			.shrinkColumnsFirst: timelinesResizeShrinkFirstButton,
		]

		preferenceObservers.append(PreferenceEnumRadioObserver(preference: \MastonautPreferences.timelinesResizeMode,
		                                                       buttonMap: timelinesResizeModeButtonMap))

		let newWindowAccountModeButtonMap: [MastonautPreferences.NewWindowAccountMode: NSButton] = [
			.ask: newWindowAccountModeAskButton,
			.pickFirstOne: newWindowAccountModePickFirstOneButton,
		]

		preferenceObservers.append(PreferenceEnumRadioObserver(preference: \MastonautPreferences.newWindowAccountMode,
		                                                       buttonMap: newWindowAccountModeButtonMap))
	}
}
