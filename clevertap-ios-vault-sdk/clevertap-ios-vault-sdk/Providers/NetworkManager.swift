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
                logger.debug("Failed to get auth response", file: #file, function: #function, line: #line)
                return .failure(error)
            }
            
        } catch {
            logger.debug("Failed to build auth request", file: #file, function: #function, line: #line)
            return .failure(.authRequestError)
        }
    }
    
    func tokenize(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, VaultError> {
        return await performOperation(
            endpoint: Constants.tokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: TokenizeResponse.self,
            operationType: .tokenize
        )
    }
    
    func detokenize(_ request: DetokenizeRequest, accessToken: String) async throws -> Result<DetokenizeResponse, VaultError> {
        return await performOperation(
            endpoint: Constants.detokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: DetokenizeResponse.self,
            operationType: .detokenize
        )
    }
    
    func batchTokenize(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, VaultError> {
        return await performOperation(
            endpoint: Constants.batchTokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: BatchTokenizeResponse.self,
            operationType: .batchTokenize
        )
    }
    
    func batchDetokenize(_ request: BatchDetokenizeRequest, accessToken: String) async throws -> Result<BatchDetokenizeResponse, VaultError> {
        return await performOperation(
            endpoint: Constants.batchDetokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: BatchDetokenizeResponse.self,
            operationType: .batchDetokenize
        )
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
                logger.debug("Operation \(operation) failed: \(error.localizedDescription)", file: #file, function: #function, line: #line)
            }
            
        } catch {
            logger.debug("Network operation \(operation) failed with exception: \(error.localizedDescription)", file: #file, function: #function, line: #line)
        }
        
        return .failure(.networkError)
    }
    
    private func performOperation<TRequest: Codable, TResponse: Codable>(
        endpoint: String,
        request: TRequest,
        accessToken: String,
        responseType: TResponse.Type,
        operationType: NetworkOperationType
    ) async -> Result<TResponse, VaultError> {
        let operationName = "\(operationType.rawValue)"
        
        do {
            let urlRequest = try requestBuilder.buildRequest(
                endpoint: endpoint,
                body: request,
                accessToken: accessToken
            )
            
            let result = await performRequest(request: urlRequest, operation: operationName) { data, response in
                return self.responseHandler.handleResponse(data: data, response: response, responseType: responseType)
            }
            
            switch result {
            case .success(let response):
                logger.info("Operation \(operationName) succeeded", file: #file, function: #function, line: #line)
                return .success(response)
                
            case .failure(let error):
                logger.debug("Operation \(operationName) failed: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                return .failure(error)
            }
            
        } catch {
            logger.debug("Failed to build request", file: #file, function: #function, line: #line)
            return .failure(.buildRequestError)
        }
    }
}
