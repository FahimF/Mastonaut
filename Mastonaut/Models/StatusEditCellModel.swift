//
//  StatusEditCellModel.swift
//  Mastonaut
//
//  Created by Sören Kuklau on 08.01.23.
//  Copyright © 2023 Bruno Philipe. All rights reserved.
//

import Foundation
import CoreTootin

class StatusEditCellModel: NSObject {
	let statusEdit: StatusEdit

	@objc private(set) dynamic
	var authorAvatar: NSImage

	init(statusEdit: StatusEdit) {
		self.statusEdit = statusEdit
		authorAvatar = #imageLiteral(resourceName: "missing")
		super.init()
		loadAvatars()
	}

	func loadAvatars() {
		loadAccountAvatar(for: statusEdit) { [weak self] in self?.authorAvatar = $0 }
	}

	func loadAccountAvatar(for statusEdit: StatusEdit, completion: @escaping (NSImage) -> Void) {
		AppDelegate.shared.avatarImageCache.fetchImage(account: statusEdit.account) { result in
			switch result {
			case .inCache(let avatarImage):
				assert(Thread.isMainThread)
				completion(avatarImage)
			case .loaded(let avatarImage):
				DispatchQueue.main.async { completion(avatarImage) }
			case .noImage:
				DispatchQueue.main.async { completion(#imageLiteral(resourceName: "missing")) }
			}
		}
	}
}
