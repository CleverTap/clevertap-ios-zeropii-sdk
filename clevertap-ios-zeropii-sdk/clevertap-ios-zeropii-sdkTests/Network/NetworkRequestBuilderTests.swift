//
//  NetworkRequestBuilderTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class NetworkRequestBuilderTests: XCTestCase {

    private var builder: NetworkRequestBuilder!
    private let baseURL = "https://api.example.com/"
    private let endpoint = "api/tokenization/getToken"
    private let accessToken = "test-bearer-token"

    override func setUpWithError() throws {
        let config = NetworkConfiguration(tokenizationBaseURL: baseURL)
        builder = NetworkRequestBuilder(configuration: config, logger: ZeroPiiLogger.shared)
    }

    override func tearDownWithError() throws {
        builder = nil
    }

    // MARK: - URL Construction

    func testBuildRequest_constructsCorrectURL() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.url?.absoluteString, baseURL + endpoint)
    }

    func testBuildRequest_usesPostMethod() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.httpMethod, "POST")
    }

    // MARK: - Headers

    func testBuildRequest_setsAuthorizationHeader() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(accessToken)")
    }

    func testBuildRequest_setsContentTypeHeader() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testBuildRequest_setsEncryptedHeader_whenEncryptedTrue() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken,
            encrypted: true
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Encrypted"), "true")
    }

    func testBuildRequest_omitsEncryptedHeader_whenEncryptedFalse() throws {
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken,
            encrypted: false
        )
        XCTAssertNil(request.value(forHTTPHeaderField: "Encrypted"))
    }

    func testBuildRequest_encryptedDefaultIsTrue() throws {
        // Default value for encrypted should be true
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Encrypted"), "true")
    }

    // MARK: - Body

    func testBuildRequest_encodesBodyAsJSON() throws {
        let value = "test@email.com"
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: TokenizeRequest(value: value),
            accessToken: accessToken
        )
        XCTAssertNotNil(request.httpBody)
        let decoded = try JSONDecoder().decode(TokenizeRequest.self, from: request.httpBody!)
        XCTAssertEqual(decoded.value, value)
    }

    func testBuildRequest_encodesBatchBody() throws {
        let values = ["a@test.com", "b@test.com"]
        let request = try builder.buildRequest(
            endpoint: "api/tokenization/tokens/batch",
            body: BatchTokenizeRequest(values: values),
            accessToken: accessToken
        )
        XCTAssertNotNil(request.httpBody)
        let decoded = try JSONDecoder().decode(BatchTokenizeRequest.self, from: request.httpBody!)
        XCTAssertEqual(decoded.values, values)
    }

    func testBuildRequest_encodesEncryptedRequest() throws {
        let encReq = EncryptedRequest(itp: "payload", itk: "key", itv: "iv")
        let request = try builder.buildRequest(
            endpoint: endpoint,
            body: encReq,
            accessToken: accessToken
        )
        XCTAssertNotNil(request.httpBody)
        let decoded = try JSONDecoder().decode(EncryptedRequest.self, from: request.httpBody!)
        XCTAssertEqual(decoded.itp, "payload")
        XCTAssertEqual(decoded.itk, "key")
        XCTAssertEqual(decoded.itv, "iv")
    }

    // MARK: - Error Cases

    func testBuildRequest_invalidBaseURL_throwsInvalidBaseURL() {
        // A space inside the host authority ("http:// ...") causes URL(string:) to return nil
        let invalidConfig = NetworkConfiguration(tokenizationBaseURL: "http:// invalid.com/")
        let invalidBuilder = NetworkRequestBuilder(configuration: invalidConfig, logger: ZeroPiiLogger.shared)

        XCTAssertThrowsError(
            try invalidBuilder.buildRequest(
                endpoint: endpoint,
                body: TokenizeRequest(value: "test"),
                accessToken: accessToken
            )
        ) { error in
            XCTAssertEqual(error as? ZeroPiiError, .invalidBaseURL)
        }
    }

    func testBuildRequest_emptyEndpoint_stillBuildsURL() throws {
        // Empty endpoint appended to valid base should still produce a valid URL
        let request = try builder.buildRequest(
            endpoint: "",
            body: TokenizeRequest(value: "test"),
            accessToken: accessToken
        )
        XCTAssertEqual(request.url?.absoluteString, baseURL)
    }

    // MARK: - Different Access Tokens

    func testBuildRequest_differentAccessTokens_useCorrectBearer() throws {
        let tokens = ["token-abc", "token-xyz", "Bearer already-bearer"]
        for token in tokens {
            let request = try builder.buildRequest(
                endpoint: endpoint,
                body: TokenizeRequest(value: "test"),
                accessToken: token
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
        }
    }
}
