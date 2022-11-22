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
	let log = XCGLogger(identifier: "advancedLogger")
	let file = AutoRotatingFileDestination(writeToFile: "~/Documents/Mastonaut.log", identifier: "org.farook.Mastonaut", shouldAppend: true, maxTimeInterval: 86400)
	// Customize as needed
	file.showThreadName = true
	file.logQueue = XCGLogger.logQueue
	// Add the destination to the logger
	log.add(destination: file)
	return log
}()
