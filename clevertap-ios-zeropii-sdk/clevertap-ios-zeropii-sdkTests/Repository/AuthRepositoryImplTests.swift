//
//  AuthRepositoryImplTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class AuthRepositoryImplTests: XCTestCase {

    // MARK: - getAccessToken: No cached token

    func testGetAccessToken_noCache_fetchesFromProvider() async {
        let provider = MockAccessTokenProvider(token: "fresh-token", expiresInSeconds: 3600)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        let result = await repo.getAccessToken()

        XCTAssertEqual(result, .success("fresh-token"))
        XCTAssertEqual(provider.fetchCallCount, 1)
    }

    // MARK: - getAccessToken: Valid cached token

    func testGetAccessToken_validCache_returnsCachedToken() async {
        let provider = MockAccessTokenProvider(token: "cached-token", expiresInSeconds: 3600)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        // First call fetches from provider
        _ = await repo.getAccessToken()
        // Second call should use cached token
        let result = await repo.getAccessToken()

        XCTAssertEqual(result, .success("cached-token"))
        XCTAssertEqual(provider.fetchCallCount, 1, "Provider should be called only once when token is valid")
    }

    // MARK: - getAccessToken: Expired token

    func testGetAccessToken_expiredToken_refetchesFromProvider() async {
        // expiresInSeconds: 0 → token expires immediately (within 30s buffer → invalid)
        let provider = MockAccessTokenProvider(token: "first-token", expiresInSeconds: 0)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        // First call fetches and caches token
        _ = await repo.getAccessToken()

        // Token with 0s expiry is within the 30s buffer → invalid
        // Second call should re-fetch
        _ = await repo.getAccessToken()

        XCTAssertEqual(provider.fetchCallCount, 2, "Provider should be called again for expired token")
    }

    // MARK: - getAccessToken: Provider error

    func testGetAccessToken_providerError_returnsAuthenticationFailed() async {
        let error = NSError(domain: "TestError", code: -1, userInfo: nil)
        let provider = MockAccessTokenProvider(error: error)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        let result = await repo.getAccessToken()

        XCTAssertEqual(result, .failure(.authenticationFailed))
    }

    // MARK: - getAccessToken: Provider returns nil token info

    func testGetAccessToken_nilTokenInfo_returnsAuthenticationFailed() async {
        let provider = MockAccessTokenProvider() // no token, no error → both nil
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        let result = await repo.getAccessToken()

        XCTAssertEqual(result, .failure(.authenticationFailed))
    }

    // MARK: - refreshAccessToken

    func testRefreshAccessToken_alwaysFetchesFromProvider() async {
        let provider = MockAccessTokenProvider(token: "token-v1", expiresInSeconds: 3600)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        // Warm the cache
        _ = await repo.getAccessToken()
        XCTAssertEqual(provider.fetchCallCount, 1)

        // refreshAccessToken should bypass cache and call provider again
        let result = await repo.refreshAccessToken()

        XCTAssertEqual(result, .success("token-v1"))
        XCTAssertEqual(provider.fetchCallCount, 2)
    }

    func testRefreshAccessToken_providerError_returnsAuthenticationFailed() async {
        let error = NSError(domain: "TestError", code: -1, userInfo: nil)
        let provider = MockAccessTokenProvider(error: error)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        let result = await repo.refreshAccessToken()

        XCTAssertEqual(result, .failure(.authenticationFailed))
    }

    // MARK: - isTokenValid

    func testIsTokenValid_noToken_returnsFalse() {
        let provider = MockAccessTokenProvider()
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        XCTAssertFalse(repo.isTokenValid())
    }

    func testIsTokenValid_tokenWith31SecondExpiry_returnsTrue() async {
        // 31s expiry > 30s buffer → valid
        let provider = MockAccessTokenProvider(token: "valid-token", expiresInSeconds: 31)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        _ = await repo.getAccessToken()

        XCTAssertTrue(repo.isTokenValid())
    }

    func testIsTokenValid_tokenWith29SecondExpiry_returnsFalse() async {
        // 29s expiry < 30s buffer → invalid
        let provider = MockAccessTokenProvider(token: "expiring-token", expiresInSeconds: 29)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        _ = await repo.getAccessToken()

        XCTAssertFalse(repo.isTokenValid())
    }

    func testIsTokenValid_tokenWithZeroExpiry_returnsFalse() async {
        let provider = MockAccessTokenProvider(token: "expired-token", expiresInSeconds: 0)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        _ = await repo.getAccessToken()

        XCTAssertFalse(repo.isTokenValid())
    }

    func testIsTokenValid_tokenWith3600SecondExpiry_returnsTrue() async {
        let provider = MockAccessTokenProvider(token: "long-lived-token", expiresInSeconds: 3600)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        _ = await repo.getAccessToken()

        XCTAssertTrue(repo.isTokenValid())
    }

    // MARK: - Token value is stored correctly

    func testGetAccessToken_returnsCorrectTokenString() async {
        let expectedToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test"
        let provider = MockAccessTokenProvider(token: expectedToken, expiresInSeconds: 3600)
        let repo = AuthRepositoryImpl(tokenProvider: provider, logger: ZeroPiiLogger.shared)

        let result = await repo.getAccessToken()

        XCTAssertEqual(result, .success(expectedToken))
    }
}
