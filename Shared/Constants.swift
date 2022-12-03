//
//  Constants.swift
//  Mastonaut
//
//  Created by Fahim Farook on 27/11/2022.
//  Copyright © 2022 Bruno Philipe. All rights reserved.
//

import Foundation

let appGroup = Bundle.main.object(forInfoDictionaryKey: "MTNAppGroupIdentifier") as? String ?? ""
let prefs = UserDefaults(suiteName: appGroup) ?? .standard


