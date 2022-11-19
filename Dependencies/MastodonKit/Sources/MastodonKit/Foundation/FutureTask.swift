//
//  FutureTask.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 10/03/19.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class FutureTask: NSObject {

    public internal(set) var task: URLSessionDataTask? {
        didSet {
            if let task = self.task {
                resolutionHandler?(task)
            }
        }
    }

    public var resolutionHandler: ((URLSessionDataTask) -> Void)? {
        didSet {
            if let task = self.task {
                resolutionHandler?(task)
            }
        }
    }
}
