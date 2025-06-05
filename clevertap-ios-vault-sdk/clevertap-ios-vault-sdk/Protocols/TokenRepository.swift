//
//  TokenRepository.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol defining tokenization operations
protocol TokenRepository {
    
    // MARK: - Single Operations
    
    /// Tokenizes a single sensitive value
    /// - Parameter value: The sensitive value to tokenize
    /// - Returns: The tokenization result
    func tokenize(_ value: String) async -> TokenizeResult
    
    /// Retrieves the original value for a given token
    /// - Parameter token: The token to detokenize
    /// - Returns: The detokenization result
    func detokenize(_ token: String) async -> DetokenizeResult
    
    // MARK: - Batch Operations
    
    /// Tokenizes multiple sensitive values in a single operation
    /// - Parameter values: Array of sensitive values to tokenize
    /// - Returns: The batch tokenization result
    func batchTokenize(_ values: [String]) async -> BatchTokenizeResult
    
    /// Retrieves original values for multiple tokens in a single operation
    /// - Parameter tokens: Array of tokens to detokenize
    /// - Returns: The batch detokenization result
    func batchDetokenize(_ tokens: [String]) async -> BatchDetokenizeResult
}
