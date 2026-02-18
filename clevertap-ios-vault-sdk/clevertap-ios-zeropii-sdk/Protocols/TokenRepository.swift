//
//  TokenRepository.swift
//  clevertap-ios-zeropii-sdk
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
    func tokenize(_ value: String) async -> TokenResult
    
    // MARK: - Batch Operations

    /// Tokenizes multiple sensitive values in a single operation
    /// - Parameter values: Array of sensitive values to tokenize
    /// - Returns: The batch tokenization result
    func batchTokenize(_ values: [String]) async -> BatchTokenResult
}
