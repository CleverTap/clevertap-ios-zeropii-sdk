//
//  TokenRepositoryImplTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class TokenRepositoryImplTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a standard mock auth repo that always returns a valid token.
    private func makeAuthRepo(token: String = "mock-access-token") -> MockAuthRepository {
        let repo = MockAuthRepository()
        repo.getAccessTokenResult = .success(token)
        return repo
    }

    /// Creates a successful TokenizeResponse.
    private func makeTokenizeResponse(token: String = "TOK_123") -> TokenizeResponse {
        TokenizeResponse(token: .string(token), exists: false, newlyCreated: true, dataType: "string")
    }

    /// Creates a successful BatchTokenizeResponse with given tokens.
    private func makeBatchTokenizeResponse(tokens: [String] = ["TOK_A", "TOK_B"]) -> BatchTokenizeResponse {
        let items = tokens.enumerated().map { idx, tok in
            BatchTokenItem(originalValue: "value_\(idx)", token: tok, exists: false, newlyCreated: true, dataType: "string")
        }
        let summary = BatchTokenizeSummary(processedCount: tokens.count, existingCount: 0, newlyCreatedCount: tokens.count)
        return BatchTokenizeResponse(results: items, summary: summary)
    }

    /// Encrypts a Codable value using the given manager and returns an EncryptedResponse suitable for mocking.
    @available(iOS 13.0, tvOS 13.0, *)
    private func makeEncryptedResponse<T: Encodable>(
        from value: T,
        using manager: EncryptionManager
    ) -> EncryptedResponse? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        guard case .success(let itp, _, let itv) = manager.encrypt(data: data) else { return nil }
        return EncryptedResponse(itp: itp, itv: itv)
    }

    // MARK: - Single Tokenize: Guard Conditions

    func testTokenize_emptyValue_returnsError() async {
        let mockProvider = MockNetworkProvider()
        let mockAuth = makeAuthRepo()
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: mockAuth,
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("")

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for empty value, got \(result)")
        }
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 0)
        XCTAssertEqual(mockProvider.tokenizeCallCount, 0)
    }

    // MARK: - Single Tokenize: Auth Failure

    func testTokenize_authFailure_returnsError() async {
        let mockProvider = MockNetworkProvider()
        let mockAuth = MockAuthRepository()
        mockAuth.getAccessTokenResult = .failure(.authenticationFailed)
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: mockAuth,
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error when auth fails, got \(result)")
        }
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 0)
    }

    // MARK: - Single Tokenize: Plain Fallback (Encryption Disabled)

    func testTokenize_encryptionDisabled_fallsBackToPlain() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "PLAIN_TOKEN"))

        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        XCTAssertEqual(mockProvider.tokenizeCallCount, 0, "Encrypted path should not be called")
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 1, "Plain path should be called")
        if case .success(let token, _, _, _) = result {
            XCTAssertEqual(token, "PLAIN_TOKEN")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    func testTokenize_encryptionDisabled_plainFails_returnsError() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizePlainResult = .failure(ZeroPiiNetworkFailure(error: .networkError, httpStatusCode: nil))

        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error, got \(result)")
        }
    }

    // MARK: - Single Tokenize: 419 Fallback

    func testTokenize_receives419_fallsBackToPlain() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .failure(ZeroPiiNetworkFailure(error: .decryptionFailed, httpStatusCode: 419))
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "FALLBACK_TOKEN"))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        guard #available(iOS 13.0, tvOS 13.0, *) else {
            // On pre-iOS 13, createEncryptedRequest returns nil so encryption is already skipped
            return
        }

        let result = await repo.tokenize("test@email.com")

        XCTAssertEqual(mockProvider.tokenizeCallCount, 1, "Encrypted call should have been made once")
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 1, "Plain fallback should have been called")
        if case .success(let token, _, _, _) = result {
            XCTAssertEqual(token, "FALLBACK_TOKEN")
        } else {
            XCTFail("Expected success after 419 fallback, got \(result)")
        }
    }

    func testTokenize_receives419_subsequentCallSkipsEncryption() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .failure(ZeroPiiNetworkFailure(error: .decryptionFailed, httpStatusCode: 419))
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "TOKEN"))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        // First call triggers 419 and sets the encryptionDisabledDueToFailure flag
        _ = await repo.tokenize("first@email.com")

        mockProvider.reset()
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "SECOND_TOKEN"))

        // Second call should skip encrypted path entirely
        _ = await repo.tokenize("second@email.com")

        XCTAssertEqual(mockProvider.tokenizeCallCount, 0, "Encrypted path should be skipped after 419")
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 1, "Should go directly to plain")
    }

    // MARK: - Single Tokenize: Non-419 Network Failure

    func testTokenize_networkError_propagatesError() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .failure(ZeroPiiNetworkFailure(error: .networkError, httpStatusCode: nil))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for network failure, got \(result)")
        }
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 0, "Plain should not be called for non-419 error")
    }

    func testTokenize_serverError_propagatesError() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .failure(ZeroPiiNetworkFailure(error: .serverError, httpStatusCode: 500))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for server error, got \(result)")
        }
    }

    // MARK: - Single Tokenize: Encrypted Success Path

    func testTokenize_encryptedSuccess_returnsCorrectToken() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let expectedResponse = makeTokenizeResponse(token: "ENC_TOKEN_ABC")

        guard let encResponse = makeEncryptedResponse(from: expectedResponse, using: encManager) else {
            XCTFail("Failed to create encrypted test response")
            return
        }

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .success(encResponse)

        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.tokenize("test@email.com")

        XCTAssertEqual(mockProvider.tokenizeCallCount, 1)
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 0)

        if case .success(let token, let exists, let newlyCreated, let dataType) = result {
            XCTAssertEqual(token, "ENC_TOKEN_ABC")
            XCTAssertFalse(exists)
            XCTAssertTrue(newlyCreated)
            XCTAssertEqual(dataType, "string")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    func testTokenize_encryptedSuccess_requestContainsCorrectValue() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let encResponse = makeEncryptedResponse(from: makeTokenizeResponse(), using: encManager)!

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .success(encResponse)

        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(token: "expected-access-token"),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        _ = await repo.tokenize("value@test.com")

        // Verify the access token was passed correctly
        XCTAssertEqual(mockProvider.lastTokenizeAccessToken, "expected-access-token")
    }

    // MARK: - Batch Tokenize: Guard Conditions

    func testBatchTokenize_emptyValues_returnsError() async {
        let mockProvider = MockNetworkProvider()
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize([])

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for empty batch, got \(result)")
        }
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 0)
    }

    func testBatchTokenize_exceedsMaxBatchSize_returnsError() async {
        let mockProvider = MockNetworkProvider()
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let oversizedBatch = Array(repeating: "value", count: 1001)
        let result = await repo.batchTokenize(oversizedBatch)

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for oversized batch, got \(result)")
        }
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 0)
    }

    func testBatchTokenize_exactlyMaxBatchSize_doesNotReturnSizeError() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizePlainResult = .success(
            makeBatchTokenizeResponse(tokens: Array(repeating: "TOK", count: 1000))
        )
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let maxBatch = Array(repeating: "value", count: 1000)
        let result = await repo.batchTokenize(maxBatch)

        // Should proceed (not fail with size error)
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 1)
        if case .error(let message, _) = result {
            XCTAssertFalse(message.contains("maximum"), "Should not be a size error")
        }
    }

    // MARK: - Batch Tokenize: Auth Failure

    func testBatchTokenize_authFailure_returnsError() async {
        let mockProvider = MockNetworkProvider()
        let mockAuth = MockAuthRepository()
        mockAuth.getAccessTokenResult = .failure(.authenticationFailed)
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: mockAuth,
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize(["a@test.com"])

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error when auth fails, got \(result)")
        }
    }

    // MARK: - Batch Tokenize: Plain Fallback (Encryption Disabled)

    func testBatchTokenize_encryptionDisabled_fallsBackToPlain() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["BATCH_TOK_1", "BATCH_TOK_2"]))

        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize(["a@test.com", "b@test.com"])

        XCTAssertEqual(mockProvider.batchTokenizeCallCount, 0, "Encrypted path should not be called")
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 1, "Plain path should be called")

        if case .success(let items, let summary) = result {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(summary.processedCount, 2)
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    // MARK: - Batch Tokenize: 419 Fallback

    func testBatchTokenize_receives419_fallsBackToPlain() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizeResult = .failure(ZeroPiiNetworkFailure(error: .decryptionFailed, httpStatusCode: 419))
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["FALLBACK_A"]))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize(["a@test.com"])

        XCTAssertEqual(mockProvider.batchTokenizeCallCount, 1)
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 1)

        if case .success(let items, _) = result {
            XCTAssertEqual(items.first?.token, "FALLBACK_A")
        } else {
            XCTFail("Expected success after 419 fallback, got \(result)")
        }
    }

    func testBatchTokenize_receives419_subsequentTokenizeSkipsEncryption() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizeResult = .failure(ZeroPiiNetworkFailure(error: .decryptionFailed, httpStatusCode: 419))
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["T1"]))
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "PLAIN_TOKEN"))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        // Trigger the 419 via batch tokenize
        _ = await repo.batchTokenize(["a@test.com"])

        mockProvider.reset()
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "PLAIN_TOKEN"))

        // Subsequent single tokenize should also skip encryption
        _ = await repo.tokenize("b@test.com")

        XCTAssertEqual(mockProvider.tokenizeCallCount, 0, "Single tokenize encrypted path should be skipped")
        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 1)
    }

    func testTokenize_receives419_subsequentBatchSkipsEncryption() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizeResult = .failure(ZeroPiiNetworkFailure(error: .decryptionFailed, httpStatusCode: 419))
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse(token: "T1"))
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["B1"]))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        // Trigger the 419 via single tokenize
        _ = await repo.tokenize("a@test.com")

        mockProvider.reset()
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["B1"]))

        // Subsequent batch tokenize should also skip encryption
        _ = await repo.batchTokenize(["b@test.com"])

        XCTAssertEqual(mockProvider.batchTokenizeCallCount, 0, "Batch encrypted path should be skipped")
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 1)
    }

    // MARK: - Batch Tokenize: Encrypted Success Path

    func testBatchTokenize_encryptedSuccess_returnsCorrectTokens() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let expectedBatchResponse = makeBatchTokenizeResponse(tokens: ["ENC_BATCH_A", "ENC_BATCH_B"])

        guard let encResponse = makeEncryptedResponse(from: expectedBatchResponse, using: encManager) else {
            XCTFail("Failed to create encrypted test response")
            return
        }

        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizeResult = .success(encResponse)

        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize(["a@test.com", "b@test.com"])

        XCTAssertEqual(mockProvider.batchTokenizeCallCount, 1)
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 0)

        if case .success(let items, let summary) = result {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].token, "ENC_BATCH_A")
            XCTAssertEqual(items[1].token, "ENC_BATCH_B")
            XCTAssertEqual(summary.processedCount, 2)
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    // MARK: - Batch Tokenize: Non-419 Network Failure

    func testBatchTokenize_networkError_propagatesError() async {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let mockProvider = MockNetworkProvider()
        mockProvider.batchTokenizeResult = .failure(ZeroPiiNetworkFailure(error: .networkError, httpStatusCode: nil))

        let encManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        let result = await repo.batchTokenize(["test@email.com"])

        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error for network failure, got \(result)")
        }
        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 0)
    }

    // MARK: - Plain Tokenize: Values are forwarded correctly

    func testTokenize_plainPath_forwardsValueToNetwork() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizePlainResult = .success(makeTokenizeResponse())

        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        _ = await repo.tokenize("unique@value.com")

        XCTAssertEqual(mockProvider.lastTokenizePlainRequest?.value, "unique@value.com")
    }

    func testBatchTokenize_plainPath_forwardsValuesToNetwork() async {
        let mockProvider = MockNetworkProvider()
        let values = ["a@test.com", "b@test.com", "c@test.com"]
        mockProvider.batchTokenizePlainResult = .success(makeBatchTokenizeResponse(tokens: ["T1", "T2", "T3"]))

        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let repo = TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: makeAuthRepo(),
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: DefaultRetryPolicy(maxRetries: 0)
        )

        _ = await repo.batchTokenize(values)

        XCTAssertEqual(mockProvider.lastBatchTokenizePlainRequest?.values, values)
    }
}
