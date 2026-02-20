//
//  ZeroPiiErrorTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class ZeroPiiErrorTests: XCTestCase {

    // MARK: - Raw Values

    func testUnauthorizedRawValue() {
        XCTAssertEqual(ZeroPiiError.unauthorized.rawValue, 401)
    }

    func testDecryptionFailedRawValue() {
        XCTAssertEqual(ZeroPiiError.decryptionFailed.rawValue, 419)
    }

    func testAuthenticationFailedRawValue() {
        XCTAssertEqual(ZeroPiiError.authenticationFailed.rawValue, 1000)
    }

    func testTokenisationFailedRawValue() {
        XCTAssertEqual(ZeroPiiError.tokenisationFalied.rawValue, 1001)
    }

    func testInvalidTokenisationResponseRawValue() {
        XCTAssertEqual(ZeroPiiError.invalidTokenisationResponse.rawValue, 1002)
    }

    func testNetworkErrorRawValue() {
        XCTAssertEqual(ZeroPiiError.networkError.rawValue, 1003)
    }

    func testBatchTokenisationFailedRawValue() {
        XCTAssertEqual(ZeroPiiError.batchTokenisationFalied.rawValue, 1007)
    }

    func testInvalidBatchTokenisationResponseRawValue() {
        XCTAssertEqual(ZeroPiiError.invalidBatchTokenisationResponse.rawValue, 1008)
    }

    func testInvalidBaseURLRawValue() {
        XCTAssertEqual(ZeroPiiError.invalidBaseURL.rawValue, 1011)
    }

    func testJsonParsingErrorRawValue() {
        XCTAssertEqual(ZeroPiiError.jsonParsingError.rawValue, 1012)
    }

    func testServerErrorRawValue() {
        XCTAssertEqual(ZeroPiiError.serverError.rawValue, 1013)
    }

    func testBuildRequestErrorRawValue() {
        XCTAssertEqual(ZeroPiiError.buildRequestError.rawValue, 1015)
    }

    func testBadRequestRawValue() {
        XCTAssertEqual(ZeroPiiError.badRequest.rawValue, 1016)
    }

    func testRateLimitExceededRawValue() {
        XCTAssertEqual(ZeroPiiError.rateLimitExceeded.rawValue, 1017)
    }

    func testForbiddenRawValue() {
        XCTAssertEqual(ZeroPiiError.forbidden.rawValue, 1018)
    }

    func testNotFoundRawValue() {
        XCTAssertEqual(ZeroPiiError.notFound.rawValue, 1019)
    }

    func testMethodNotAllowedRawValue() {
        XCTAssertEqual(ZeroPiiError.methodNotAllowed.rawValue, 1020)
    }

    // MARK: - Error Descriptions

    func testAuthenticationFailedDescription() {
        XCTAssertEqual(ZeroPiiError.authenticationFailed.errorDescription, "Authentication failed error.")
    }

    func testTokenisationFailedDescription() {
        XCTAssertEqual(ZeroPiiError.tokenisationFalied.errorDescription, "Tokenisation failed error.")
    }

    func testInvalidTokenisationResponseDescription() {
        XCTAssertEqual(ZeroPiiError.invalidTokenisationResponse.errorDescription, "Invalid tokenization response type.")
    }

    func testNetworkErrorDescription() {
        XCTAssertEqual(ZeroPiiError.networkError.errorDescription, "Network error.")
    }

    func testUnauthorizedDescription() {
        XCTAssertEqual(ZeroPiiError.unauthorized.errorDescription, "Unauthorized error.")
    }

    func testDecryptionFailedDescription() {
        XCTAssertEqual(ZeroPiiError.decryptionFailed.errorDescription, "Backend decryption failure.")
    }

    func testBatchTokenisationFailedDescription() {
        XCTAssertEqual(ZeroPiiError.batchTokenisationFalied.errorDescription, "Batch tokenisation failed error.")
    }

    func testInvalidBatchTokenisationResponseDescription() {
        XCTAssertEqual(ZeroPiiError.invalidBatchTokenisationResponse.errorDescription, "Invalid batch tokenization response type.")
    }

    func testInvalidBaseURLDescription() {
        XCTAssertEqual(ZeroPiiError.invalidBaseURL.errorDescription, "Invalid Auth base URL")
    }

    func testJsonParsingErrorDescription() {
        XCTAssertEqual(ZeroPiiError.jsonParsingError.errorDescription, "Failed to parse JSON")
    }

    func testServerErrorDescription() {
        XCTAssertEqual(ZeroPiiError.serverError.errorDescription, "Server error")
    }

    func testBuildRequestErrorDescription() {
        XCTAssertEqual(ZeroPiiError.buildRequestError.errorDescription, "Failed to build request")
    }

    func testBadRequestDescription() {
        XCTAssertEqual(ZeroPiiError.badRequest.errorDescription, "Bad request")
    }

    func testRateLimitExceededDescription() {
        XCTAssertEqual(ZeroPiiError.rateLimitExceeded.errorDescription, "Rate limit exceeded")
    }

    func testForbiddenDescription() {
        XCTAssertEqual(ZeroPiiError.forbidden.errorDescription, "Forbidden")
    }

    func testNotFoundDescription() {
        XCTAssertEqual(ZeroPiiError.notFound.errorDescription, "Not found")
    }

    func testMethodNotAllowedDescription() {
        XCTAssertEqual(ZeroPiiError.methodNotAllowed.errorDescription, "Method not allowed")
    }

    // MARK: - Equatability

    func testErrorEquality() {
        XCTAssertEqual(ZeroPiiError.unauthorized, ZeroPiiError.unauthorized)
        XCTAssertEqual(ZeroPiiError.decryptionFailed, ZeroPiiError.decryptionFailed)
        XCTAssertNotEqual(ZeroPiiError.unauthorized, ZeroPiiError.networkError)
        XCTAssertNotEqual(ZeroPiiError.decryptionFailed, ZeroPiiError.tokenisationFalied)
    }

    // MARK: - Init from Raw Value

    func testInitFromRawValue_knownValues() {
        XCTAssertEqual(ZeroPiiError(rawValue: 401), .unauthorized)
        XCTAssertEqual(ZeroPiiError(rawValue: 419), .decryptionFailed)
        XCTAssertEqual(ZeroPiiError(rawValue: 1000), .authenticationFailed)
        XCTAssertEqual(ZeroPiiError(rawValue: 1001), .tokenisationFalied)
        XCTAssertEqual(ZeroPiiError(rawValue: 1003), .networkError)
        XCTAssertEqual(ZeroPiiError(rawValue: 1016), .badRequest)
        XCTAssertEqual(ZeroPiiError(rawValue: 1017), .rateLimitExceeded)
        XCTAssertEqual(ZeroPiiError(rawValue: 1020), .methodNotAllowed)
    }

    func testInitFromRawValue_unknownValue_returnsNil() {
        XCTAssertNil(ZeroPiiError(rawValue: 999))
        XCTAssertNil(ZeroPiiError(rawValue: 0))
        XCTAssertNil(ZeroPiiError(rawValue: -1))
    }

    // MARK: - Error Protocol Conformance

    func testIsError() {
        let error: Error = ZeroPiiError.networkError
        XCTAssertNotNil(error)
    }

    func testCanBeUsedInResult() {
        let result: Result<String, ZeroPiiError> = .failure(.networkError)
        if case .failure(let err) = result {
            XCTAssertEqual(err, .networkError)
        } else {
            XCTFail("Expected failure")
        }
    }
}
