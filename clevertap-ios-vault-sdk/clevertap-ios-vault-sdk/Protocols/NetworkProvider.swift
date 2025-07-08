//
//  NetworkProvider.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol defining network operations for communicating with the Vault API
protocol NetworkProvider {
    
    // MARK: - Authentication Operations
    
    /// Requests an access token using OAuth2 client credentials flow
    /// - Parameters:
    ///   - clientId: OAuth2 client identifier
    ///   - clientSecret: OAuth2 client secret
    /// - Returns: Result containing AuthTokenResponse on success or VaultError on failure
    /// - Note: This method handles the complete OAuth2 flow including proper header formatting
    func getAccessToken(clientId: String, clientSecret: String) async throws -> Result<AuthTokenResponse, VaultError>
    
    // MARK: - Single Value Operations
    
    /// Tokenizes a single sensitive value using plain text transmission
    /// - Parameters:
    ///   - request: TokenizeRequest containing the sensitive value
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing TokenizeResponse with the token or VaultError on failure
    /// - Note: Use encrypted version for production environments
    func tokenize(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, VaultError>
    
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
    func batchTokenize(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, VaultError>
    
    /// Detokenizes multiple tokens in a single request using plain text transmission
    /// - Parameters:
    ///   - request: BatchDetokenizeRequest containing array of tokens
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing BatchDetokenizeResponse with values array or VaultError on failure
    /// - Note: Batch size is limited by Constants.maxBatchSize
    func batchDetokenize(_ request: BatchDetokenizeRequest, accessToken: String) async throws -> Result<BatchDetokenizeResponse, VaultError>
}
