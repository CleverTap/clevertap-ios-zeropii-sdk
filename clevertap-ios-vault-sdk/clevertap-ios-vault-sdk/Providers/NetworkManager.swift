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
        let operation = "getAccessToken"
        
        do {
            let request = try requestBuilder.buildAuthRequest(clientId: clientId, clientSecret: clientSecret)

            let result = await performRequest(request: request, operation: operation) { data, response in
                return self.responseHandler.handleAuthResponse(data: data, response: response)
            }
            
            switch result {
            case .success(let authResponse):
                return .success(authResponse)
            case .failure(let error):
                logger.error("Failed to get auth response", file: #file, function: #function, line: #line)
                return .failure(error)
            }
            
        } catch {
            logger.error("Failed to build auth request", file: #file, function: #function, line: #line)
            return .failure(.authRequestError)
        }
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
    
    private func performRequest<T>(
        request: URLRequest,
        operation: String,
        handler: @escaping (Data, URLResponse) -> Result<T, VaultError>
    ) async -> Result<T, VaultError> {
        do {
            let (data, response) = try await session.data(for: request)
            let result = handler(data, response)
            
            switch result {
            case .success:
                logger.info("Operation \(operation) succeeded", file: #file, function: #function, line: #line)
                return result
                
            case .failure(let error):
                logger.error("Operation \(operation) failed: \(error.localizedDescription)", file: #file, function: #function, line: #line)
            }
            
        } catch {
            logger.error("Network operation \(operation) failed with exception: \(error.localizedDescription)", file: #file, function: #function, line: #line)
        }
        
        return .failure(.networkError)
    }
}
