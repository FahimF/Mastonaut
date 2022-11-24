//
//  ClientType.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 6/12/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public protocol ClientType {
    /// The user access token used to perform the network requests.
    var accessToken: String? { get set }
    /// The base URL for this client.
    var baseURL: String { get }
    /// The delegate object for the client. Can be shared between several client instances.
    var delegate: ClientDelegate? { get set }

    /// Mastodon Client's initializer.
    ///
    /// - Parameters:
    ///   - baseURL: The Mastodon instance URL
    ///   - accessToken: The user access token used to perform the network requests (optional).
    ///   - session: The URLSession used to perform the network requests.
    init(baseURL: String, accessToken: String?, session: URLSession, delegate: ClientDelegate?)

    /// Performs the network request.
    ///
    /// If a task can be created immediately, the returned future will be already populated.
    ///
    /// - Parameters:
    ///   - request: The request to be performed.
    ///   - resumeImmediately: Whether the `URLSessionDataTask` should be resumed before returning.
    ///   - completion: The completion block to be called when the request is complete.
    ///   - result: The request result.
    /// - Returns: `FutureTask` A future that will be populated with the task that will execute the request.
    @discardableResult
    func run<Model>(_ request: Request<Model>,
                    resumeImmediately: Bool,
                    completion: @escaping (_ result: MKResult<Model>) -> Void) -> FutureTask?

    /// Performs several network requests and aggregates their results.
    ///
    /// - Parameters:
    ///   - requestProvider: A block that is given a pagination parameter and should return the next page request.
    ///   - completion: The completion block to be called when the request is complete.
    ///   - result: The request result.
    func runAndAggregateAllPages<Model: Codable>(requestProvider: @escaping (Pagination) -> Request<[Model]>,
                                                 completion: @escaping (MKResult<[Model]>) -> Void)

    /// Adds a new observer to the receiver. The receiver keeps a weak reference to the observer, and thus calling
    /// `removeObserver(_:)` is not required if the observer is going to be released.
    ///
    /// - Parameter observer: The new observer
    func addObserver(_ observer: ClientObserver)

    /// Removes the given observer from the set of observers the receiver references. If the given object is not
    /// registered as an observer, this method does nothing.
    ///
    /// - Parameter observer: The observer to be removed.
    func removeObserver(_ observer: ClientObserver)
}

public extension ClientType {

    /// Performs the network request.
    ///
    /// - Parameters:
    ///   - request: The request to be performed.
    ///   - completion: The completion block to be called when the request is complete.
    ///   - result: The request result.
    func run<Model>(_ request: Request<Model>, completion: @escaping (_ result: MKResult<Model>) -> Void) {
        run(request, resumeImmediately: true, completion: completion)
    }
}

public protocol ClientObserver: AnyObject {

    /// Invoked when the client that the receiver observes is given a new `accessToken`.
    ///
    /// - Parameters:
    ///   - client: The client that had its `accessToken` changed.
    ///   - accessToken: The new `accessToken`.
    func client(_ client: ClientType, didUpdate accessToken: String)
}
