//
//  ClientDelegate.swift
//  MastodonKit
//
//  Created by Bruno Philipe on 10/03/19.
//  Copyright © 2019 MastodonKit. All rights reserved.
//

import Foundation

/// The Client delegate is responsibe for fetching a new authorization token if the use being currently used expires.
public protocol ClientDelegate: AnyObject {

    var isRequestingNewAccessToken: Bool { get }

    func clientProducedUnauthorizedError(_ client: ClientType)
}
