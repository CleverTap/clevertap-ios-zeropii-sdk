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
    private var networkConfiguration: NetworkConfiguration
    private let requestBuilder: NetworkRequestBuilder
    private let responseHandler: NetworkResponseHandler
    
    public var configuration: NetworkConfiguration {
        return networkConfiguration
    }
    
    public init(configuration: NetworkConfiguration, logger: VaultLoggerProtocol = VaultLogger.shared) {
        self.networkConfiguration = configuration
        self.logger = logger
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 15 * 2
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Add custom headers
        for (key, value) in configuration.customHeaders {
            sessionConfig.httpAdditionalHeaders?[key] = value
        }
        
        self.session = URLSession(configuration: sessionConfig)
        self.requestBuilder = NetworkRequestBuilder(configuration: configuration, logger: logger)
        self.responseHandler = NetworkResponseHandler(logger: logger)
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
