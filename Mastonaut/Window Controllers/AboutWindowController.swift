//
//  AboutWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 04.02.19.
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

class AboutWindowController: NSWindowController {
	@IBOutlet var versionLabel: NSTextField!

	private lazy var acknowledgementsWindowController = AcknowledgementsWindowController()

	override func windowDidLoad() {
		super.windowDidLoad()
		if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
			versionLabel.stringValue = 🔠("Version: %@ (%@)", version, build)
		}
	}

	override var windowNibName: NSNib.Name? {
		return "AboutWindowController"
	}

	@IBAction func openHomepage(_: Any?) {
		NSWorkspace.shared.open(URL(string: "https://github.com/FahimF/Mastonaut")!)
	}

	@IBAction func openPrivacyPolicy(_: Any?) {
		NSWorkspace.shared.open(URL(string: "https://github.com/FahimF/Mastonaut")!)
	}

	@IBAction func orderFrontAcknowledgementsWindow(_ sender: Any?) {
		acknowledgementsWindowController.showWindow(sender)
	}
}
