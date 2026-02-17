//
//  NetworkProvider.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol defining network operations for communicating with the Vault API
protocol NetworkProvider {

    // MARK: - Single Value Operations
    
    /// Tokenizes a single sensitive value using plain text transmission
    /// - Parameters:
    ///   - request: TokenizeRequest containing the sensitive value
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing TokenizeResponse with the token or VaultError on failure
    /// - Note: Use encrypted version for production environments
    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, VaultError>
    
    /// Detokenizes a single token to retrieve the original value using plain text transmission
    /// - Parameters:
    ///   - request: DetokenizeRequest containing the token to convert back
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing DetokenizeResponse with original value or VaultError on failure
    /// - Note: Use encrypted version for production environments
    func detokenize(_ request: DetokenizeRequest, accessToken: String) async throws -> Result<DetokenizeResponse, VaultError>
    
    // MARK: - Batch Operations
    
    /// Tokenizes multiple sensitive values in a single request using plain text transmission
    /// - Parameters:
    ///   - request: BatchTokenizeRequest containing array of sensitive values
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing BatchTokenizeResponse with tokens array or VaultError on failure
    /// - Note: Batch size is limited by Constants.maxBatchSize
    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, VaultError>
    
    /// Detokenizes multiple tokens in a single request using plain text transmission
    /// - Parameters:
    ///   - request: BatchDetokenizeRequest containing array of tokens
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing BatchDetokenizeResponse with values array or VaultError on failure
    /// - Note: Batch size is limited by Constants.maxBatchSize
    func batchDetokenize(_ request: BatchDetokenizeRequest, accessToken: String) async throws -> Result<BatchDetokenizeResponse, VaultError>
}
