//
//  NetworkResponseHandlerTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class NetworkResponseHandlerTests: XCTestCase {

    private var handler: NetworkResponseHandler!

    override func setUpWithError() throws {
        handler = NetworkResponseHandler(logger: ZeroPiiLogger.shared)
    }

    override func tearDownWithError() throws {
        handler = nil
    }

    // MARK: - Helpers

    private struct TestResponse: Codable, Equatable {
        let message: String
    }

    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func makeValidJSON() -> Data {
        return "{\"message\":\"hello\"}".data(using: .utf8)!
    }

    private func makeInvalidJSON() -> Data {
        return "not-valid-json".data(using: .utf8)!
    }

    private func makeTokenizeResponseJSON(token: String = "TOK123") -> Data {
        return """
        {"token":"\(token)","exists":false,"newlyCreated":true,"dataType":"string"}
        """.data(using: .utf8)!
    }

    // MARK: - 200 Success

    func testHandleResponse_200_validJSON_returnsSuccess() {
        let data = makeValidJSON()
        let response = makeHTTPResponse(statusCode: 200)

        let result = handler.handleResponse(data: data, response: response, responseType: TestResponse.self)

        if case .success(let decoded) = result {
            XCTAssertEqual(decoded.message, "hello")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    func testHandleResponse_200_invalidJSON_returnsJsonParsingError() {
        let data = makeInvalidJSON()
        let response = makeHTTPResponse(statusCode: 200)

        let result = handler.handleResponse(data: data, response: response, responseType: TestResponse.self)

        XCTAssertEqual(result, .failure(.jsonParsingError))
    }

    func testHandleResponse_200_emptyData_returnsJsonParsingError() {
        let data = Data()
        let response = makeHTTPResponse(statusCode: 200)

        let result = handler.handleResponse(data: data, response: response, responseType: TestResponse.self)

        XCTAssertEqual(result, .failure(.jsonParsingError))
    }

    func testHandleResponse_200_decodesTokenizeResponse() {
        let data = makeTokenizeResponseJSON()
        let response = makeHTTPResponse(statusCode: 200)

        let result = handler.handleResponse(data: data, response: response, responseType: TokenizeResponse.self)

        if case .success(let tokenizeResponse) = result {
            XCTAssertEqual(tokenizeResponse.token.stringValue, "TOK123")
            XCTAssertFalse(tokenizeResponse.exists)
            XCTAssertTrue(tokenizeResponse.newlyCreated)
            XCTAssertEqual(tokenizeResponse.dataType, "string")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }

    // MARK: - 4xx Status Codes

    func testHandleResponse_400_returnsBadRequest() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 400),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.badRequest))
    }

    func testHandleResponse_401_returnsUnauthorized() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 401),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.unauthorized))
    }

    func testHandleResponse_403_returnsForbidden() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 403),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.forbidden))
    }

    func testHandleResponse_404_returnsNotFound() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 404),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.notFound))
    }

    func testHandleResponse_405_returnsMethodNotAllowed() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 405),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.methodNotAllowed))
    }

    func testHandleResponse_419_returnsDecryptionFailed() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 419),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.decryptionFailed))
    }

    func testHandleResponse_429_returnsRateLimitExceeded() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 429),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.rateLimitExceeded))
    }

    // MARK: - 5xx Status Codes

    func testHandleResponse_500_returnsServerError() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 500),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.serverError))
    }

    func testHandleResponse_502_returnsServerError() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 502),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.serverError))
    }

    func testHandleResponse_503_returnsServerError() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 503),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.serverError))
    }

    func testHandleResponse_504_returnsServerError() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 504),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.serverError))
    }

    func testHandleResponse_unknownStatusCode_returnsServerError() {
        let result = handler.handleResponse(
            data: makeInvalidJSON(),
            response: makeHTTPResponse(statusCode: 418),
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.serverError))
    }

    // MARK: - Non-HTTP Response

    func testHandleResponse_nonHTTPResponse_returnsNetworkError() {
        let nonHTTPResponse = URLResponse(
            url: URL(string: "https://api.example.com/test")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let result = handler.handleResponse(
            data: makeValidJSON(),
            response: nonHTTPResponse,
            responseType: TestResponse.self
        )
        XCTAssertEqual(result, .failure(.networkError))
    }

    // MARK: - Encrypted Response

    func testHandleResponse_200_decodesEncryptedResponse() {
        let json = "{\"itp\":\"encryptedPayload\",\"itv\":\"ivValue\"}"
        let data = json.data(using: .utf8)!
        let response = makeHTTPResponse(statusCode: 200)

        let result = handler.handleResponse(data: data, response: response, responseType: EncryptedResponse.self)

        if case .success(let encResponse) = result {
            XCTAssertEqual(encResponse.itp, "encryptedPayload")
            XCTAssertEqual(encResponse.itv, "ivValue")
        } else {
            XCTFail("Expected success, got \(result)")
        }
    }
}

