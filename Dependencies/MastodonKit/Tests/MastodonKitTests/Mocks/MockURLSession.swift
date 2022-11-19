//
//  MockURLSession.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

class MockURLSession: URLSession {
    var lastRequest: URLRequest?
    var lastCompletionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    var lastReturnedDataTask: MockURLSessionDataTask?

    var automaticCompletionResponses: [(Data?, URLResponse?, Error?)]?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        lastRequest = request
        lastCompletionHandler = completionHandler
        lastReturnedDataTask = MockURLSessionDataTask()

        if automaticCompletionResponses?.isEmpty == false, let response = automaticCompletionResponses?.removeFirst() {
            completionHandler(response.0, response.1, response.2)
        }

        return lastReturnedDataTask!
    }
}
