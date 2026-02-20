//
//  MockNetworkProvider.swift
//  clevertap-ios-zeropii-sdkTests
//

import Foundation
@testable import clevertap_ios_zeropii_sdk

class MockNetworkProvider: NetworkProvider {

    // MARK: - Tokenize (Encrypted)
    var tokenizeResult: Result<EncryptedResponse, ZeroPiiError> = .failure(.tokenisationFalied)
    private(set) var tokenizeCallCount = 0
    private(set) var lastTokenizeRequest: EncryptedRequest?
    private(set) var lastTokenizeAccessToken: String?

    // MARK: - Tokenize (Plain)
    var tokenizePlainResult: Result<TokenizeResponse, ZeroPiiError> = .failure(.tokenisationFalied)
    private(set) var tokenizePlainCallCount = 0
    private(set) var lastTokenizePlainRequest: TokenizeRequest?

    // MARK: - Batch Tokenize (Encrypted)
    var batchTokenizeResult: Result<EncryptedResponse, ZeroPiiError> = .failure(.batchTokenisationFalied)
    private(set) var batchTokenizeCallCount = 0
    private(set) var lastBatchTokenizeRequest: EncryptedRequest?

    // MARK: - Batch Tokenize (Plain)
    var batchTokenizePlainResult: Result<BatchTokenizeResponse, ZeroPiiError> = .failure(.batchTokenisationFalied)
    private(set) var batchTokenizePlainCallCount = 0
    private(set) var lastBatchTokenizePlainRequest: BatchTokenizeRequest?

    func tokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError> {
        tokenizeCallCount += 1
        lastTokenizeRequest = request
        lastTokenizeAccessToken = accessToken
        return tokenizeResult
    }

    func tokenizePlain(_ request: TokenizeRequest, accessToken: String) async throws -> Result<TokenizeResponse, ZeroPiiError> {
        tokenizePlainCallCount += 1
        lastTokenizePlainRequest = request
        return tokenizePlainResult
    }

    func batchTokenize(_ request: EncryptedRequest, accessToken: String) async throws -> Result<EncryptedResponse, ZeroPiiError> {
        batchTokenizeCallCount += 1
        lastBatchTokenizeRequest = request
        return batchTokenizeResult
    }

    func batchTokenizePlain(_ request: BatchTokenizeRequest, accessToken: String) async throws -> Result<BatchTokenizeResponse, ZeroPiiError> {
        batchTokenizePlainCallCount += 1
        lastBatchTokenizePlainRequest = request
        return batchTokenizePlainResult
    }

    func reset() {
        tokenizeCallCount = 0
        tokenizePlainCallCount = 0
        batchTokenizeCallCount = 0
        batchTokenizePlainCallCount = 0
        lastTokenizeRequest = nil
        lastTokenizePlainRequest = nil
        lastBatchTokenizeRequest = nil
        lastBatchTokenizePlainRequest = nil
        lastTokenizeAccessToken = nil
    }
}
