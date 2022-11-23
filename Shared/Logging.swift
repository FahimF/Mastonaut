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
	let fm = FileManager.default
	let dir = "/Users/Shared/Public/logs"
	let path = "/Users/Shared/Public/logs/Mastonaut.log"
	if !fm.fileExists(atPath: dir) {
		do {
			try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
			if fm.createFile(atPath: path, contents: nil) {
				NSLog("Created log file successfully")
			} else {
				NSLog("Failed to create log file")
			}
		} catch {
			NSLog("Error creating folder path: \(error)")
		}
	}
	let url = URL(fileURLWithPath: path)
	let file = AutoRotatingFileDestination(writeToFile: url, identifier: "org.farook.Mastonaut", shouldAppend: true, maxTimeInterval: 86400)
	// Customize as needed
	file.showThreadName = true
	file.logQueue = XCGLogger.logQueue
	// Add the destination to the logger
	log.add(destination: file)
	return log
}()
