//
//  NetworkManager.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 08/07/25.
//

import Foundation

class NetworkManager: NetworkProvider {
    
    private let session: URLSession
    private let logger: ZeroPiiLoggerProtocol
    private var networkConfiguration: NetworkConfiguration
    private let requestBuilder: NetworkRequestBuilder
    private let responseHandler: NetworkResponseHandler
    
    public var configuration: NetworkConfiguration {
        return networkConfiguration
    }
    
    public init(configuration: NetworkConfiguration, logger: ZeroPiiLoggerProtocol = ZeroPiiLogger.shared) {
        self.networkConfiguration = configuration
        self.logger = logger
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 15 * 2
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: sessionConfig)
        self.requestBuilder = NetworkRequestBuilder(configuration: configuration, logger: logger)
        self.responseHandler = NetworkResponseHandler(logger: logger)
    }
    
    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError> {
        return await performOperation(
            endpoint: Constants.tokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: EncryptedResponse.self,
            operationType: .tokenize
        )
    }
    
    func detokenize(_ request: DetokenizeRequest, accessToken: String) async throws -> Result<DetokenizeResponse, ZeroPiiError> {
        return await performOperation(
            endpoint: Constants.detokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: DetokenizeResponse.self,
            operationType: .detokenize
        )
    }
    
    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError> {
        return await performOperation(
            endpoint: Constants.batchTokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: EncryptedResponse.self,
            operationType: .batchTokenize
        )
    }
    
    func batchDetokenize(_ request: BatchDetokenizeRequest, accessToken: String) async throws -> Result<BatchDetokenizeResponse, ZeroPiiError> {
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
        handler: @escaping (Data, URLResponse) -> Result<T, ZeroPiiError>
    ) async -> Result<T, ZeroPiiError> {
        do {
            let (data, response) = try await session.data(for: request)
            let result = handler(data, response)
            
            switch result {
            case .success:
                logger.info("Operation \(operation) succeeded", file: #file, line: #line)
                return result
                
            case .failure(let error):
                logger.debug("Operation \(operation) failed: \(error.localizedDescription)", file: #file, line: #line)
            }
            
        } catch {
            logger.debug("Network operation \(operation) failed with exception: \(error.localizedDescription)", file: #file, line: #line)
        }
        
        return .failure(.networkError)
    }
    
    private func performOperation<TRequest: Codable, TResponse: Codable>(
        endpoint: String,
        request: TRequest,
        accessToken: String,
        responseType: TResponse.Type,
        operationType: NetworkOperationType
    ) async -> Result<TResponse, ZeroPiiError> {
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
                logger.info("Operation \(operationName) succeeded", file: #file, line: #line)
                return .success(response)
                
            case .failure(let error):
                logger.debug("Operation \(operationName) failed: \(error.localizedDescription)", file: #file, line: #line)
                return .failure(error)
            }
            
        } catch {
            logger.debug("Failed to build request", file: #file, line: #line)
            return .failure(.buildRequestError)
        }
    }
}
