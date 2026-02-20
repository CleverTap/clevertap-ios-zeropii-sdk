//
//  TokenModelsTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class TokenModelsTests: XCTestCase {

    // MARK: - TokenizeRequest

    func testTokenizeRequest_encode() throws {
        let request = TokenizeRequest(value: "test@email.com")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["value"] as? String, "test@email.com")
    }

    func testTokenizeRequest_decode() throws {
        let json = #"{"value":"hello@world.com"}"#.data(using: .utf8)!
        let request = try JSONDecoder().decode(TokenizeRequest.self, from: json)
        XCTAssertEqual(request.value, "hello@world.com")
    }

    func testTokenizeRequest_roundTrip() throws {
        let original = TokenizeRequest(value: "unique@test.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TokenizeRequest.self, from: encoded)
        XCTAssertEqual(decoded.value, original.value)
    }

    // MARK: - TokenizeResponse

    func testTokenizeResponse_decode_withStringToken() throws {
        let json = #"{"token":"TOK_ABC","exists":false,"newlyCreated":true,"dataType":"string"}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(TokenizeResponse.self, from: json)

        XCTAssertEqual(response.token.stringValue, "TOK_ABC")
        XCTAssertFalse(response.exists)
        XCTAssertTrue(response.newlyCreated)
        XCTAssertEqual(response.dataType, "string")
    }

    func testTokenizeResponse_decode_withIntToken() throws {
        let json = #"{"token":99887,"exists":true,"newlyCreated":false,"dataType":"integer"}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(TokenizeResponse.self, from: json)

        XCTAssertEqual(response.token.stringValue, "99887")
        XCTAssertTrue(response.exists)
        XCTAssertFalse(response.newlyCreated)
        XCTAssertEqual(response.dataType, "integer")
    }

    func testTokenizeResponse_decode_withNullDataType() throws {
        let json = #"{"token":"TOK_X","exists":false,"newlyCreated":true,"dataType":null}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(TokenizeResponse.self, from: json)

        XCTAssertNil(response.dataType)
    }

    func testTokenizeResponse_decode_withMissingDataType() throws {
        let json = #"{"token":"TOK_X","exists":false,"newlyCreated":true}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(TokenizeResponse.self, from: json)

        XCTAssertNil(response.dataType)
    }

    // MARK: - BatchTokenizeRequest

    func testBatchTokenizeRequest_encode() throws {
        let values = ["a@test.com", "b@test.com", "c@test.com"]
        let request = BatchTokenizeRequest(values: values)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["values"] as? [String], values)
    }

    func testBatchTokenizeRequest_decode() throws {
        let json = #"{"values":["x@test.com","y@test.com"]}"#.data(using: .utf8)!
        let request = try JSONDecoder().decode(BatchTokenizeRequest.self, from: json)
        XCTAssertEqual(request.values, ["x@test.com", "y@test.com"])
    }

    func testBatchTokenizeRequest_emptyValues_encodesCorrectly() throws {
        let request = BatchTokenizeRequest(values: [])
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(BatchTokenizeRequest.self, from: data)
        XCTAssertTrue(decoded.values.isEmpty)
    }

    // MARK: - BatchTokenItem

    func testBatchTokenItem_decode_withStringToken() throws {
        let json = """
        {
            "originalValue": "test@email.com",
            "token": "BATCH_TOK_123",
            "exists": false,
            "newlyCreated": true,
            "dataType": "string"
        }
        """.data(using: .utf8)!
        let item = try JSONDecoder().decode(BatchTokenItem.self, from: json)

        XCTAssertEqual(item.originalValue, "test@email.com")
        XCTAssertEqual(item.token, "BATCH_TOK_123")
        XCTAssertFalse(item.exists)
        XCTAssertTrue(item.newlyCreated)
        XCTAssertEqual(item.dataType, "string")
    }

    func testBatchTokenItem_decode_withIntToken() throws {
        let json = """
        {
            "originalValue": "12345",
            "token": 67890,
            "exists": true,
            "newlyCreated": false,
            "dataType": "integer"
        }
        """.data(using: .utf8)!
        let item = try JSONDecoder().decode(BatchTokenItem.self, from: json)

        XCTAssertEqual(item.token, "67890")
        XCTAssertTrue(item.exists)
        XCTAssertFalse(item.newlyCreated)
    }

    func testBatchTokenItem_decode_withNullDataType() throws {
        let json = """
        {"originalValue":"v","token":"T","exists":false,"newlyCreated":true,"dataType":null}
        """.data(using: .utf8)!
        let item = try JSONDecoder().decode(BatchTokenItem.self, from: json)
        XCTAssertNil(item.dataType)
    }

    func testBatchTokenItem_directInit() {
        let item = BatchTokenItem(
            originalValue: "original",
            token: "TOK_DIRECT",
            exists: true,
            newlyCreated: false,
            dataType: "string"
        )
        XCTAssertEqual(item.originalValue, "original")
        XCTAssertEqual(item.token, "TOK_DIRECT")
        XCTAssertTrue(item.exists)
        XCTAssertFalse(item.newlyCreated)
        XCTAssertEqual(item.dataType, "string")
    }

    // MARK: - BatchTokenizeSummary

    func testBatchTokenizeSummary_decode() throws {
        let json = #"{"processedCount":10,"existingCount":3,"newlyCreatedCount":7}"#.data(using: .utf8)!
        let summary = try JSONDecoder().decode(BatchTokenizeSummary.self, from: json)

        XCTAssertEqual(summary.processedCount, 10)
        XCTAssertEqual(summary.existingCount, 3)
        XCTAssertEqual(summary.newlyCreatedCount, 7)
    }

    func testBatchTokenizeSummary_directInit() {
        let summary = BatchTokenizeSummary(processedCount: 5, existingCount: 2, newlyCreatedCount: 3)
        XCTAssertEqual(summary.processedCount, 5)
        XCTAssertEqual(summary.existingCount, 2)
        XCTAssertEqual(summary.newlyCreatedCount, 3)
    }

    func testBatchTokenizeSummary_allZero() {
        let summary = BatchTokenizeSummary(processedCount: 0, existingCount: 0, newlyCreatedCount: 0)
        XCTAssertEqual(summary.processedCount, 0)
    }

    // MARK: - BatchTokenizeResponse

    func testBatchTokenizeResponse_decode() throws {
        let json = """
        {
            "results": [
                {"originalValue":"a@test.com","token":"TOK_A","exists":false,"newlyCreated":true,"dataType":"string"},
                {"originalValue":"b@test.com","token":"TOK_B","exists":true,"newlyCreated":false,"dataType":"string"}
            ],
            "summary": {"processedCount":2,"existingCount":1,"newlyCreatedCount":1}
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(BatchTokenizeResponse.self, from: json)

        XCTAssertEqual(response.results.count, 2)
        XCTAssertEqual(response.results[0].token, "TOK_A")
        XCTAssertEqual(response.results[1].token, "TOK_B")
        XCTAssertEqual(response.summary.processedCount, 2)
        XCTAssertEqual(response.summary.existingCount, 1)
        XCTAssertEqual(response.summary.newlyCreatedCount, 1)
    }

    func testBatchTokenizeResponse_emptyResults() throws {
        let json = """
        {"results":[],"summary":{"processedCount":0,"existingCount":0,"newlyCreatedCount":0}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(BatchTokenizeResponse.self, from: json)
        XCTAssertTrue(response.results.isEmpty)
    }

    // MARK: - EncryptedRequest

    func testEncryptedRequest_encode() throws {
        let req = EncryptedRequest(itp: "payload123", itk: "key456", itv: "iv789")
        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["itp"] as? String, "payload123")
        XCTAssertEqual(json?["itk"] as? String, "key456")
        XCTAssertEqual(json?["itv"] as? String, "iv789")
    }

    func testEncryptedRequest_decode() throws {
        let json = #"{"itp":"encPayload","itk":"encKey","itv":"encIV"}"#.data(using: .utf8)!
        let req = try JSONDecoder().decode(EncryptedRequest.self, from: json)

        XCTAssertEqual(req.itp, "encPayload")
        XCTAssertEqual(req.itk, "encKey")
        XCTAssertEqual(req.itv, "encIV")
    }

    // MARK: - EncryptedResponse

    func testEncryptedResponse_decode() throws {
        let json = #"{"itp":"respPayload","itv":"respIV"}"#.data(using: .utf8)!
        let resp = try JSONDecoder().decode(EncryptedResponse.self, from: json)

        XCTAssertEqual(resp.itp, "respPayload")
        XCTAssertEqual(resp.itv, "respIV")
    }

    func testEncryptedResponse_roundTrip() throws {
        let original = EncryptedResponse(itp: "myPayload", itv: "myIV")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EncryptedResponse.self, from: encoded)

        XCTAssertEqual(decoded.itp, original.itp)
        XCTAssertEqual(decoded.itv, original.itv)
    }
}
