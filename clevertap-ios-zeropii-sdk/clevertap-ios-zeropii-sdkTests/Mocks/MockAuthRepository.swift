//
//  MockAuthRepository.swift
//  clevertap-ios-zeropii-sdkTests
//

import Foundation
@testable import clevertap_ios_zeropii_sdk

class MockAuthRepository: AuthRepository {

    var getAccessTokenResult: Result<String, ZeroPiiError> = .success("mock-access-token")
    var refreshAccessTokenResult: Result<String, ZeroPiiError> = .success("mock-refreshed-token")
    var tokenValidResult: Bool = true

    private(set) var getAccessTokenCallCount = 0
    private(set) var refreshAccessTokenCallCount = 0

    func getAccessToken() async -> Result<String, ZeroPiiError> {
        getAccessTokenCallCount += 1
        return getAccessTokenResult
    }

    func refreshAccessToken() async -> Result<String, ZeroPiiError> {
        refreshAccessTokenCallCount += 1
        return refreshAccessTokenResult
    }

    func isTokenValid() -> Bool {
        return tokenValidResult
    }
}
