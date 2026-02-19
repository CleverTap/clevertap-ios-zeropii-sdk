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
    
    /// Tokenizes a single sensitive value using encrypted request
    /// - Parameters:
    ///   - request: EncryptedRequest containing the encrypted payload
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing EncryptedResponse or ZeroPiiError on failure
    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError>

    /// Tokenizes a single sensitive value without encryption in transit
    /// - Parameters:
    ///   - request: TokenizeRequest containing the sensitive value
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing TokenizeResponse with the token or ZeroPiiError on failure
    func tokenizePlain(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, ZeroPiiError>

    // MARK: - Batch Operations

    /// Tokenizes multiple sensitive values in a single request using encrypted request
    /// - Parameters:
    ///   - request: EncryptedRequest containing the encrypted payload
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing EncryptedResponse or ZeroPiiError on failure
    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError>

    /// Tokenizes multiple sensitive values without encryption in transit
    /// - Parameters:
    ///   - request: BatchTokenizeRequest containing array of sensitive values
    ///   - accessToken: Valid OAuth2 access token for authentication
    /// - Returns: Result containing BatchTokenizeResponse or ZeroPiiError on failure
    func batchTokenizePlain(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, ZeroPiiError>
}
