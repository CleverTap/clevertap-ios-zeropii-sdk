//
//  TokenResults.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Represents the result of a tokenization process, which can either be a success with token details
/// or an error with a descriptive message.
enum TokenResult {

    /// Represents a successful tokenization result.
    ///
    /// - Parameters:
    ///   - token: The generated token as a string. This may be `nil` if no token was produced.
    ///   - exists: A Boolean indicating whether the token already existed for the given input value.
    ///   - newlyCreated: A Boolean indicating whether the token was newly created in this operation.
    ///   - dataType: The data type of the token, such as `"string"` or `"number"`.
    case success(token: String?, exists: Bool, newlyCreated: Bool, dataType: String?)
    
    /// Represents an error that occurred during tokenization.
    ///
    /// - Parameter message: A string describing the error that occurred.
    case error(message: String)
}


/// Represents the result of a batch tokenization operation, which can either be a success
/// containing multiple individual tokenization results and a summary, or an error describing the failure.
enum BatchTokenResult {
    
    /// Indicates a successful batch tokenization.
    ///
    /// - Parameters:
    ///   - results: An array of individual tokenization results for each item in the batch.
    ///   - summary: A summary object containing statistics and metadata about the batch operation.
    case success(results: [BatchTokenItem], summary: BatchTokenizeSummary)
    
    /// Indicates an error occurred during the batch tokenization process.
    ///
    /// - Parameter message: A descriptive error message explaining what went wrong.
    case error(message: String)
}

