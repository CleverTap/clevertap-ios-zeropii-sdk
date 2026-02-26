//
//  MockAccessTokenProvider.swift
//  clevertap-ios-zeropii-sdkTests
//

import Foundation
@testable import clevertap_ios_zeropii_sdk

class MockAccessTokenProvider: NSObject, AccessTokenProvider {

    private var tokenInfo: AccessTokenInfo?
    private var error: Error?
    private(set) var fetchCallCount = 0

    override init() {
        super.init()
    }

    convenience init(token: String, expiresInSeconds: Int = 3600) {
        self.init()
        self.tokenInfo = AccessTokenInfo(token: token, expiresInSeconds: expiresInSeconds)
    }

    convenience init(error: Error) {
        self.init()
        self.error = error
    }

    func fetchToken(completion: @escaping (AccessTokenInfo?, Error?) -> Void) {
        fetchCallCount += 1
        completion(tokenInfo, error)
    }
}
