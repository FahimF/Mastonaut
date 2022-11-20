//
//  Client.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Client: ClientType {

    private let session: URLSession
    private var retryQueue: OperationQueue?
    private let observers = ClientObserverList()

    public let baseURL: String
    public weak var delegate: ClientDelegate?

    public var accessToken: String? {
        didSet {
            if accessToken != oldValue { accessTokenDidChange() }
        }
    }

    public required init(baseURL: String,
                         accessToken: String? = nil,
                         session: URLSession = .shared,
                         delegate: ClientDelegate? = nil) {
        self.baseURL = baseURL
        self.session = session
        self.accessToken = accessToken
        self.delegate = delegate
    }

    @discardableResult
    public func run<Model: Codable>(_ request: Request<Model>,
                                    resumeImmediately: Bool,
                                    completion: @escaping (Result<Model>) -> Void) -> FutureTask? {
        run(request, existingFuture: nil, resumeImmediately: resumeImmediately, completion: completion)
    }

    @discardableResult
    private func run<Model: Codable>(_ request: Request<Model>,
                                     existingFuture: FutureTask?,
                                     resumeImmediately: Bool,
                                     completion: @escaping (Result<Model>) -> Void) -> FutureTask? {

        guard delegate?.isRequestingNewAccessToken != true else {
            let future = FutureTask()
            scheduleRequestForRetry(request, future: future, completion: completion)
            return future
        }

        guard
            let components = URLComponents(baseURL: baseURL, request: request),
            let url = components.url
        else {
            completion(.failure(ClientError.malformedURL))
            return nil
        }

        let urlRequest = URLRequest(url: url, request: request, accessToken: accessToken)
        let future = existingFuture ?? FutureTask()

        let task = session.dataTask(with: urlRequest) { [delegate, weak self] data, response, error in
            if let error = error {
                completion(.failure(.genericError(error as NSError)))
                return
            }

            guard let data = data else {
                completion(.failure(ClientError.malformedJSON))
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                guard (response as? HTTPURLResponse)?.statusCode != 401 else {
                    self.map { delegate?.clientProducedUnauthorizedError($0) }
                    if let self = self, self.accessToken != nil, delegate?.isRequestingNewAccessToken == true {
                        self.scheduleRequestForRetry(request, future: future, completion: completion)
                    } else {
                        completion(.failure(.unauthorized))
                    }
                    return
                }
                let mastodonError = try? MastodonError.decode(data: data)
                let error: ClientError = mastodonError.map { .mastodonError($0.description) }
                                        ?? .badStatus(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
                completion(.failure(error))
                return
            }

            do {
                completion(.success(try Model.decode(data: data), httpResponse.pagination))
            } catch let parseError {
                #if DEBUG
                NSLog("Parse error: \(parseError)")
                #endif
                completion(.failure(ClientError.invalidModel))
            }
        }

        future.task = task

        if resumeImmediately {
            task.resume()
        }

        return future
    }

    public func runAndAggregateAllPages<Model: Codable>(requestProvider: @escaping (Pagination) -> Request<[Model]>,
                                                        completion: @escaping (Result<[Model]>) -> Void) {

        let aggregationQueue = DispatchQueue(label: "Aggregation", qos: .utility)
        var aggregateResults: [Model] = []

        func fetchPage(pagination: Pagination) {
            run(requestProvider(pagination)) { result in

                switch result {
                case .success(let partialResult, let newPagination):
                    aggregationQueue.async {
                        aggregateResults.append(contentsOf: partialResult)

                        if !partialResult.isEmpty, let pagination = newPagination, pagination.next != nil {
                            fetchPage(pagination: pagination)
                        } else {
                            completion(.success(aggregateResults, nil))
                        }
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        fetchPage(pagination: Pagination(next: nil, previous: nil))
    }

    // MARK: - Observer Maintenance

    public func addObserver(_ observer: ClientObserver) {
        observers.addObserver(observer)
    }

    public func removeObserver(_ observer: ClientObserver) {
        observers.removeObserver(observer)
    }

    // MARK: - Private Methods

    private func scheduleRequestForRetry<Model>(_ request: Request<Model>,
                                                future: FutureTask,
                                                completion: @escaping (Result<Model>) -> Void) {

        let queue = retryQueue ?? {
            let queue = OperationQueue()
            queue.qualityOfService = .background
            queue.maxConcurrentOperationCount = 1
            return queue
        }()

        queue.isSuspended = true

        queue.addOperation { [unowned self] in
            self.run(request, existingFuture: future, resumeImmediately: true, completion: completion)
        }

        retryQueue = queue
    }

    private func accessTokenDidChange() {

        if let accessToken = accessToken {

            observers.allObservers.forEach({ $0.client(self, didUpdate: accessToken) })

            if let queue = retryQueue, queue.operationCount > 0 {
                queue.isSuspended = false
            }
        }
    }
}
