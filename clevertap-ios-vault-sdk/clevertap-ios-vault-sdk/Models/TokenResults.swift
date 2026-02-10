//
//  TokenResults.swift
//  clevertap-ios-vault-sdk
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


/// Represents the result of a detokenization process, which can either be a success
/// containing the original value and metadata, or an error describing what went wrong.
enum DetokenResult {
    
    /// Indicates a successful detokenization operation.
    ///
    /// - Parameters:
    ///   - value: The original value retrieved from the token. This may be `nil` if no value was found.
    ///   - exists: A Boolean indicating whether the value actually existed for the given token.
    ///   - dataType: The data type of the original value, such as `"string"` or `"number"`.
    case success(value: String?, exists: Bool, dataType: String?)
    
    /// Indicates that an error occurred during the detokenization process.
    ///
    /// - Parameter message: A descriptive error message explaining the failure.
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

/// Represents the result of a batch detokenization operation, which can either be a success
/// containing multiple individual detokenization results and a summary, or an error describing the failure.
enum BatchDetokenizeResult {
    
    /// Indicates a successful batch detokenization.
    ///
    /// - Parameters:
    ///   - results: An array of individual detokenization results for each token in the batch.
    ///   - summary: A summary object containing statistics and metadata about the batch operation.
    case success(results: [BatchDetokenItem], summary: BatchDetokenizeSummary)
    
    /// Indicates an error occurred during the batch detokenization process.
    ///
    /// - Parameter message: A descriptive error message explaining what went wrong.
    case error(message: String)
}
