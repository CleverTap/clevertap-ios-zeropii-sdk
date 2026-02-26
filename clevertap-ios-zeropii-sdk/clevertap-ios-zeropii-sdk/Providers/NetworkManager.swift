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

    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiNetworkFailure> {
        return await performOperation(
            endpoint: Constants.tokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: EncryptedResponse.self,
            operationType: .tokenize,
            encrypted: true
        )
    }

    func tokenizePlain(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, ZeroPiiNetworkFailure> {
        return await performOperation(
            endpoint: Constants.tokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: TokenizeResponse.self,
            operationType: .tokenize,
            encrypted: false
        )
    }

    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiNetworkFailure> {
        return await performOperation(
            endpoint: Constants.batchTokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: EncryptedResponse.self,
            operationType: .batchTokenize,
            encrypted: true
        )
    }

    func batchTokenizePlain(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, ZeroPiiNetworkFailure> {
        return await performOperation(
            endpoint: Constants.batchTokenizeEndpoint,
            request: request,
            accessToken: accessToken,
            responseType: BatchTokenizeResponse.self,
            operationType: .batchTokenize,
            encrypted: false
        )
    }

    private func performRequest<T>(
        request: URLRequest,
        operation: String,
        handler: @escaping (Data, URLResponse) -> (Result<T, ZeroPiiError>, Int?)
    ) async -> Result<T, ZeroPiiNetworkFailure> {
        do {
            let (data, response) = try await session.data(for: request)
            let (result, httpStatusCode) = handler(data, response)

            let mapped = result.mapError { ZeroPiiNetworkFailure(error: $0, httpStatusCode: httpStatusCode) }

            switch mapped {
            case .success:
                logger.info("Operation \(operation) succeeded", file: #file, line: #line)

            case .failure(let failure):
                logger.debug("Operation \(operation) failed with status \(failure.httpStatusCode.map(String.init) ?? "n/a"): \(failure.error.localizedDescription)", file: #file, line: #line)
            }

            return mapped

        } catch {
            logger.debug("Network operation \(operation) failed with exception: \(error.localizedDescription)", file: #file, line: #line)
        }

        return .failure(ZeroPiiNetworkFailure(error: .networkError, httpStatusCode: nil))
    }

    private func performOperation<TRequest: Codable, TResponse: Codable>(
        endpoint: String,
        request: TRequest,
        accessToken: String,
        responseType: TResponse.Type,
        operationType: NetworkOperationType,
        encrypted: Bool = true
    ) async -> Result<TResponse, ZeroPiiNetworkFailure> {
        let operationName = "\(operationType.rawValue)"

        do {
            let urlRequest = try requestBuilder.buildRequest(
                endpoint: endpoint,
                body: request,
                accessToken: accessToken,
                encrypted: encrypted
            )

            return await performRequest(request: urlRequest, operation: operationName) { data, response in
                return self.responseHandler.handleResponse(data: data, response: response, responseType: responseType)
            }

        } catch {
            logger.debug("Failed to build request", file: #file, line: #line)
            return .failure(ZeroPiiNetworkFailure(error: .buildRequestError, httpStatusCode: nil))
        }
    }
}
