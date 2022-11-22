//
//  Logging.swift
//  Mastonaut
//
//  Created by Fahim Farook on 22/11/2022.
//  Copyright © 2022 Bruno Philipe. All rights reserved.
//

import Foundation
import XCGLogger

let log: XCGLogger = {
	let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
	let file = AutoRotatingFileDestination(owner: log, writeToFile: "~/Public/Mastonaut.log", identifier: "org.farook.Mastonaut", shouldAppend: true, maxTimeInterval: 86400)
	// Customize as needed
	file.showLogIdentifier = false
	file.showFunctionName = true
	file.showThreadName = true
	file.showLevel = true
	file.showFileName = true
	file.showLineNumber = true
	file.showDate = true
	file.logQueue = XCGLogger.logQueue
	// Add the destination to the logger
	log.add(destination: file)
	return log
}()
