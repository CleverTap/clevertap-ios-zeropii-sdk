//
//  MockRetryPolicy.swift
//  clevertap-ios-zeropii-sdkTests
//

import Foundation
@testable import clevertap_ios_zeropii_sdk

class MockRetryPolicy: NSObject, RetryPolicy {

    var shouldRetryResult = false
    var retryDelayMsResult = 0

    private(set) var shouldRetryCallCount = 0
    private(set) var retryDelayCallCount = 0
    private(set) var lastAttempt: Int = -1
    private(set) var lastHttpStatusCode: NSNumber? = nil

    func shouldRetry(attempt: Int, httpStatusCode: NSNumber?) -> Bool {
        shouldRetryCallCount += 1
        lastAttempt = attempt
        lastHttpStatusCode = httpStatusCode
        return shouldRetryResult
    }

    func retryDelayMs(attempt: Int) -> Int {
        retryDelayCallCount += 1
        return retryDelayMsResult
    }

    func reset() {
        shouldRetryCallCount = 0
        retryDelayCallCount = 0
        lastAttempt = -1
        lastHttpStatusCode = nil
    }
}
