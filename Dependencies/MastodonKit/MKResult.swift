//
//  Result.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 6/6/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public enum MKResult<Model> {
    /// Success wraps a model and an optional pagination
    case success(Model, Pagination?)
    /// Failure wraps an ErrorType
    case failure(ClientError)
	
	/// Convenience getter for the value.
	var value: Model? {
		switch self {
		case .success(let value, _): return value
		case .failure: return nil
		}
	}

	/// Convenience getter for the pagination.
	var pagination: Pagination? {
		switch self {
		case .success(_, let pagination): return pagination
		case .failure: return nil
		}
	}

	/// Convenience getter for the error.
	var error: ClientError? {
		switch self {
		case .success: return nil
		case .failure(let error): return error
		}
	}

	/// Convenience getter to test whether the result is an error or not.
	var isError: Bool {
		switch self {
		case .success: return false
		case .failure: return true
		}
	}
}

