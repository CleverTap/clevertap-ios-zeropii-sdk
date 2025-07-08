//
//  NetworkManager.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 08/07/25.
//

import Foundation

class NetworkManager: NetworkProvider {
    
    private let session: URLSession
    private let logger: VaultLoggerProtocol
    
    public init(logger: VaultLoggerProtocol = VaultLogger.shared) {
        self.logger = logger
        self.session = URLSession.shared
    }
    
    func getAccessToken(clientId: String, clientSecret: String) async throws -> Result<AuthTokenResponse, VaultError> {
        // TODO
        return .failure(.unauthorized)
    }
    
    func tokenize(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, VaultError> {
        // TODO
        return .failure(.unauthorized)
    }
    
    func detokenize(_ request: DetokenizeRequest, accessToken: String) async throws -> Result<DetokenizeResponse, VaultError> {
        // TODO
        return .failure(.unauthorized)
    }
    
    func batchTokenize(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, VaultError> {
        // TODO
        return .failure(.unauthorized)
    }
    
    func batchDetokenize(_ request: BatchDetokenizeRequest, accessToken: String) async throws -> Result<BatchDetokenizeResponse, VaultError> {
        // TODO
        return .failure(.unauthorized)
    }
}
