//
//  TokenizeResultsTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class TokenizeResultsTests: XCTestCase {

    // MARK: - TokenizeResult from Success

    func testTokenizeResult_fromSuccess_isSuccess() {
        let result = TokenizeResult(result: .success(token: "TOK_123", exists: false, newlyCreated: true, dataType: "string"))

        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
    }

    func testTokenizeResult_fromSuccess_tokenIsSet() {
        let result = TokenizeResult(result: .success(token: "MY_TOKEN", exists: false, newlyCreated: true, dataType: "string"))

        XCTAssertEqual(result.token, "MY_TOKEN")
    }

    func testTokenizeResult_fromSuccess_existsIsCorrect() {
        let result = TokenizeResult(result: .success(token: "T", exists: true, newlyCreated: false, dataType: nil))

        XCTAssertTrue(result.exists)
        XCTAssertFalse(result.newlyCreated)
    }

    func testTokenizeResult_fromSuccess_newlyCreatedIsCorrect() {
        let result = TokenizeResult(result: .success(token: "T", exists: false, newlyCreated: true, dataType: nil))

        XCTAssertTrue(result.newlyCreated)
    }

    func testTokenizeResult_fromSuccess_dataTypeIsSet() {
        let result = TokenizeResult(result: .success(token: "T", exists: false, newlyCreated: true, dataType: "integer"))

        XCTAssertEqual(result.dataType, "integer")
    }

    func testTokenizeResult_fromSuccess_nilToken() {
        let result = TokenizeResult(result: .success(token: nil, exists: false, newlyCreated: false, dataType: nil))

        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.token)
    }

    func testTokenizeResult_fromSuccess_nilDataType() {
        let result = TokenizeResult(result: .success(token: "T", exists: false, newlyCreated: true, dataType: nil))

        XCTAssertNil(result.dataType)
    }

    // MARK: - TokenizeResult from Error

    func testTokenizeResult_fromError_isNotSuccess() {
        let result = TokenizeResult(result: .error(message: "Something went wrong"))

        XCTAssertFalse(result.isSuccess)
    }

    func testTokenizeResult_fromError_errorMessageIsSet() {
        let result = TokenizeResult(result: .error(message: "Network error occurred"))

        XCTAssertEqual(result.errorMessage, "Network error occurred")
    }

    func testTokenizeResult_fromError_tokenIsNil() {
        let result = TokenizeResult(result: .error(message: "Error"))

        XCTAssertNil(result.token)
    }

    func testTokenizeResult_fromError_existsIsFalse() {
        let result = TokenizeResult(result: .error(message: "Error"))

        XCTAssertFalse(result.exists)
    }

    func testTokenizeResult_fromError_newlyCreatedIsFalse() {
        let result = TokenizeResult(result: .error(message: "Error"))

        XCTAssertFalse(result.newlyCreated)
    }

    func testTokenizeResult_fromError_dataTypeIsNil() {
        let result = TokenizeResult(result: .error(message: "Error"))

        XCTAssertNil(result.dataType)
    }

    // MARK: - BatchTokenizeResult from Success

    func testBatchTokenizeResult_fromSuccess_isSuccess() {
        let items = [BatchTokenItem(originalValue: "v", token: "T", exists: false, newlyCreated: true, dataType: nil)]
        let summary = BatchTokenizeSummary(processedCount: 1, existingCount: 0, newlyCreatedCount: 1)
        let result = BatchTokenizeResult(result: .success(results: items, summary: summary))

        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
    }

    func testBatchTokenizeResult_fromSuccess_resultsAreSet() {
        let items = [
            BatchTokenItem(originalValue: "a@test.com", token: "TOK_A", exists: false, newlyCreated: true, dataType: "string"),
            BatchTokenItem(originalValue: "b@test.com", token: "TOK_B", exists: true, newlyCreated: false, dataType: "string")
        ]
        let summary = BatchTokenizeSummary(processedCount: 2, existingCount: 1, newlyCreatedCount: 1)
        let result = BatchTokenizeResult(result: .success(results: items, summary: summary))

        XCTAssertEqual(result.results.count, 2)
        XCTAssertEqual(result.results[0].token, "TOK_A")
        XCTAssertEqual(result.results[1].token, "TOK_B")
    }

    func testBatchTokenizeResult_fromSuccess_summaryIsSet() {
        let summary = BatchTokenizeSummary(processedCount: 5, existingCount: 2, newlyCreatedCount: 3)
        let result = BatchTokenizeResult(result: .success(results: [], summary: summary))

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.processedCount, 5)
        XCTAssertEqual(result.summary?.existingCount, 2)
        XCTAssertEqual(result.summary?.newlyCreatedCount, 3)
    }

    func testBatchTokenizeResult_fromSuccess_emptyResults() {
        let summary = BatchTokenizeSummary(processedCount: 0, existingCount: 0, newlyCreatedCount: 0)
        let result = BatchTokenizeResult(result: .success(results: [], summary: summary))

        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.results.isEmpty)
    }

    // MARK: - BatchTokenizeResult from Error

    func testBatchTokenizeResult_fromError_isNotSuccess() {
        let result = BatchTokenizeResult(result: .error(message: "Batch failed"))

        XCTAssertFalse(result.isSuccess)
    }

    func testBatchTokenizeResult_fromError_errorMessageIsSet() {
        let result = BatchTokenizeResult(result: .error(message: "Batch tokenization failed"))

        XCTAssertEqual(result.errorMessage, "Batch tokenization failed")
    }

    func testBatchTokenizeResult_fromError_resultsIsEmpty() {
        let result = BatchTokenizeResult(result: .error(message: "Error"))

        XCTAssertTrue(result.results.isEmpty)
    }

    func testBatchTokenizeResult_fromError_summaryIsNil() {
        let result = BatchTokenizeResult(result: .error(message: "Error"))

        XCTAssertNil(result.summary)
    }
}
