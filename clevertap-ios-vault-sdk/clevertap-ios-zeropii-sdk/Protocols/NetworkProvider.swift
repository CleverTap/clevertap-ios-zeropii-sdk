//
//  NetworkProvider.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol defining network operations for communicating with the ZeroPii API
protocol NetworkProvider {

    // MARK: - Single Value Operations
    
    /// Tokenizes a single sensitive value using plain text transmission
    /// - Parameters:
    ///   - request: TokenizeRequest containing the sensitive value
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing TokenizeResponse with the token or ZeroPiiError on failure
    /// - Note: Use encrypted version for production environments
    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError>
    
    // MARK: - Batch Operations

    /// Tokenizes multiple sensitive values in a single request using plain text transmission
    /// - Parameters:
    ///   - request: BatchTokenizeRequest containing array of sensitive values
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing BatchTokenizeResponse with tokens array or ZeroPiiError on failure
    /// - Note: Batch size is limited by Constants.maxBatchSize
    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError>
}
