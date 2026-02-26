//
//  RetryPolicyTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class RetryPolicyTests: XCTestCase {

    // MARK: - DefaultRetryPolicy: shouldRetry — retryable status codes

    func testDefaultPolicy_shouldRetry_nilStatusCode_returnsTrue() {
        // nil = network error (no HTTP response) — always retryable
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: nil))
    }

    func testDefaultPolicy_shouldRetry_500_returnsTrue() {
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 500)))
    }

    func testDefaultPolicy_shouldRetry_502_returnsTrue() {
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 502)))
    }

    func testDefaultPolicy_shouldRetry_503_returnsTrue() {
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 503)))
    }

    func testDefaultPolicy_shouldRetry_504_returnsTrue() {
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 504)))
    }

    func testDefaultPolicy_shouldRetry_429_returnsTrue() {
        let policy = DefaultRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 429)))
    }

    // MARK: - DefaultRetryPolicy: shouldRetry — non-retryable status codes

    func testDefaultPolicy_shouldRetry_400_returnsFalse() {
        let policy = DefaultRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 400)))
    }

    func testDefaultPolicy_shouldRetry_401_returnsFalse() {
        // 401 is handled internally by the SDK, but if it somehow reaches the policy it should not retry
        let policy = DefaultRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 401)))
    }

    func testDefaultPolicy_shouldRetry_403_returnsFalse() {
        let policy = DefaultRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 403)))
    }

    func testDefaultPolicy_shouldRetry_404_returnsFalse() {
        let policy = DefaultRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 404)))
    }

    func testDefaultPolicy_shouldRetry_405_returnsFalse() {
        let policy = DefaultRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 405)))
    }

    // MARK: - DefaultRetryPolicy: maxRetries enforcement

    func testDefaultPolicy_shouldRetry_exceedsMaxRetries_returnsFalse() {
        let policy = DefaultRetryPolicy(maxRetries: 1)
        // attempt=0 is within limit
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: nil))
        // attempt=1 reaches the limit
        XCTAssertFalse(policy.shouldRetry(attempt: 1, httpStatusCode: nil))
    }

    func testDefaultPolicy_shouldRetry_zeroMaxRetries_returnsFalse() {
        let policy = DefaultRetryPolicy(maxRetries: 0)
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: nil))
        XCTAssertFalse(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 500)))
    }

    func testDefaultPolicy_shouldRetry_customMaxRetries_respectsLimit() {
        let policy = DefaultRetryPolicy(maxRetries: 3)
        XCTAssertTrue(policy.shouldRetry(attempt: 0, httpStatusCode: NSNumber(value: 500)))
        XCTAssertTrue(policy.shouldRetry(attempt: 1, httpStatusCode: NSNumber(value: 500)))
        XCTAssertTrue(policy.shouldRetry(attempt: 2, httpStatusCode: NSNumber(value: 500)))
        XCTAssertFalse(policy.shouldRetry(attempt: 3, httpStatusCode: NSNumber(value: 500)))
    }

    // MARK: - DefaultRetryPolicy: retryDelayMs — exponential backoff

    func testDefaultPolicy_retryDelayMs_attempt0_returns2000() {
        let policy = DefaultRetryPolicy()
        // 1000 * 2^(0+1) = 2000ms
        XCTAssertEqual(policy.retryDelayMs(attempt: 0), 2000)
    }

    func testDefaultPolicy_retryDelayMs_attempt1_returns4000() {
        let policy = DefaultRetryPolicy()
        // 1000 * 2^(1+1) = 4000ms
        XCTAssertEqual(policy.retryDelayMs(attempt: 1), 4000)
    }

    func testDefaultPolicy_retryDelayMs_attempt2_returns8000() {
        let policy = DefaultRetryPolicy()
        // 1000 * 2^(2+1) = 8000ms
        XCTAssertEqual(policy.retryDelayMs(attempt: 2), 8000)
    }

    // MARK: - TokenRepositoryImpl: retry integration

    private func makeRepo(
        mockProvider: MockNetworkProvider,
        mockAuth: MockAuthRepository? = nil,
        retryPolicy: RetryPolicy
    ) -> TokenRepositoryImpl {
        let auth = mockAuth ?? {
            let a = MockAuthRepository()
            a.getAccessTokenResult = .success("mock-token")
            return a
        }()
        let encManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        return TokenRepositoryImpl(
            networkProvider: mockProvider,
            authRepository: auth,
            encryptionManager: encManager,
            logger: ZeroPiiLogger.shared,
            retryPolicy: retryPolicy
        )
    }

    func testTokenize_retryableError_retrySucceeds() async {
        let mockProvider = MockNetworkProvider()
        // First call fails with 500, second succeeds
        let successResponse = TokenizeResponse(token: .string("RETRY_TOKEN"), exists: false, newlyCreated: true, dataType: "string")
        mockProvider.tokenizePlainResultSequence = [
            .failure(ZeroPiiNetworkFailure(error: .serverError, httpStatusCode: 500))
        ]
        mockProvider.tokenizePlainResult = .success(successResponse)

        let retryPolicy = MockRetryPolicy()
        retryPolicy.shouldRetryResult = true
        retryPolicy.retryDelayMsResult = 0

        let repo = makeRepo(mockProvider: mockProvider, retryPolicy: retryPolicy)
        let result = await repo.tokenize("test@email.com")

        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 2, "Should have made 2 network calls (1 initial + 1 retry)")
        XCTAssertEqual(retryPolicy.shouldRetryCallCount, 1, "RetryPolicy should be consulted once")
        XCTAssertEqual(retryPolicy.lastAttempt, 0)
        XCTAssertEqual(retryPolicy.lastHttpStatusCode, NSNumber(value: 500))

        if case .success(let token, _, _, _) = result {
            XCTAssertEqual(token, "RETRY_TOKEN")
        } else {
            XCTFail("Expected success after retry, got \(result)")
        }
    }

    func testTokenize_retryableError_policyReturnsNoRetry_failsImmediately() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizePlainResult = .failure(ZeroPiiNetworkFailure(error: .serverError, httpStatusCode: 503))

        let retryPolicy = MockRetryPolicy()
        retryPolicy.shouldRetryResult = false // no retry

        let repo = makeRepo(mockProvider: mockProvider, retryPolicy: retryPolicy)
        let result = await repo.tokenize("test@email.com")

        XCTAssertEqual(mockProvider.tokenizePlainCallCount, 1, "Should only make 1 network call when policy says no retry")
        XCTAssertEqual(retryPolicy.shouldRetryCallCount, 1)
        if case .error = result {
            // expected
        } else {
            XCTFail("Expected error, got \(result)")
        }
    }

    func testTokenize_networkError_passesNilStatusCodeToPolicy() async {
        let mockProvider = MockNetworkProvider()
        mockProvider.tokenizePlainResult = .failure(ZeroPiiNetworkFailure(error: .networkError, httpStatusCode: nil))

        let retryPolicy = MockRetryPolicy()
        retryPolicy.shouldRetryResult = false

        let repo = makeRepo(mockProvider: mockProvider, retryPolicy: retryPolicy)
        _ = await repo.tokenize("test@email.com")

        XCTAssertEqual(retryPolicy.shouldRetryCallCount, 1)
        XCTAssertNil(retryPolicy.lastHttpStatusCode, "Network error should pass nil httpStatusCode to RetryPolicy")
    }

    func testTokenize_401_doesNotCallRetryPolicy() async {
        let mockProvider = MockNetworkProvider()
        // Encrypted path needed for 401 to come from network (not auth repo)
        // Use plain path for simplicity: auth repo returns success, but network returns 401
        mockProvider.tokenizePlainResult = .failure(ZeroPiiNetworkFailure(error: .unauthorized, httpStatusCode: 401))

        let mockAuth = MockAuthRepository()
        mockAuth.getAccessTokenResult = .success("token")
        mockAuth.refreshAccessTokenResult = .success("refreshed-token")

        // After refresh, second call also returns 401 (to force termination)
        mockProvider.tokenizePlainResultSequence = [
            .failure(ZeroPiiNetworkFailure(error: .unauthorized, httpStatusCode: 401))
        ]

        let retryPolicy = MockRetryPolicy()
        retryPolicy.shouldRetryResult = true

        let repo = makeRepo(mockProvider: mockProvider, mockAuth: mockAuth, retryPolicy: retryPolicy)
        _ = await repo.tokenize("test@email.com")

        XCTAssertEqual(retryPolicy.shouldRetryCallCount, 0, "RetryPolicy must NOT be called for 401 — handled internally")
    }

    func testBatchTokenize_retryableError_retrySucceeds() async {
        let mockProvider = MockNetworkProvider()
        let successResponse = BatchTokenizeResponse(
            results: [BatchTokenItem(originalValue: "a@test.com", token: "BATCH_TOK", exists: false, newlyCreated: true, dataType: "string")],
            summary: BatchTokenizeSummary(processedCount: 1, existingCount: 0, newlyCreatedCount: 1)
        )
        mockProvider.batchTokenizePlainResultSequence = [
            .failure(ZeroPiiNetworkFailure(error: .rateLimitExceeded, httpStatusCode: 429))
        ]
        mockProvider.batchTokenizePlainResult = .success(successResponse)

        let retryPolicy = MockRetryPolicy()
        retryPolicy.shouldRetryResult = true
        retryPolicy.retryDelayMsResult = 0

        let repo = makeRepo(mockProvider: mockProvider, retryPolicy: retryPolicy)
        let result = await repo.batchTokenize(["a@test.com"])

        XCTAssertEqual(mockProvider.batchTokenizePlainCallCount, 2, "Should retry once")
        XCTAssertEqual(retryPolicy.lastHttpStatusCode, NSNumber(value: 429))
        if case .success(let items, _) = result {
            XCTAssertEqual(items.first?.token, "BATCH_TOK")
        } else {
            XCTFail("Expected success after retry, got \(result)")
        }
    }
}
