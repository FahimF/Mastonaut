//
//  ClientObserverList.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 11.09.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation

public struct ClientObserverList {

    private let storage: NSPointerArray = .weakObjects()

    public init() {}

    public var count: Int {
        return storage.count
    }

    public var allObservers: [ClientObserver] {
		return storage.allObjects.compactMap({ $0 as? ClientObserver })
    }

    public func addObserver(_ observer: ClientObserver) {
        guard (storage.allObjects as? [ClientObserver])?.firstIndex(where: { $0 === observer }) == nil else {
            return
        }

        storage.addPointer(Unmanaged.passUnretained(observer as AnyObject).toOpaque())
    }

    public func removeObserver(_ observer: ClientObserver) {
        guard let index = (storage.allObjects as? [ClientObserver])?.firstIndex(where: { $0 === observer }) else {
            return
        }

        storage.removePointer(at: index)
    }
}
