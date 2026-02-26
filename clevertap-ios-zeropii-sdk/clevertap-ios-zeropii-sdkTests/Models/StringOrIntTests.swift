//
//  StringOrIntTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class StringOrIntTests: XCTestCase {

    // MARK: - stringValue

    func testStringValue_stringCase() {
        let value = StringOrInt.string("hello")
        XCTAssertEqual(value.stringValue, "hello")
    }

    func testStringValue_intCase() {
        let value = StringOrInt.int(42)
        XCTAssertEqual(value.stringValue, "42")
    }

    func testStringValue_intZero() {
        XCTAssertEqual(StringOrInt.int(0).stringValue, "0")
    }

    func testStringValue_intNegative() {
        XCTAssertEqual(StringOrInt.int(-99).stringValue, "-99")
    }

    func testStringValue_emptyString() {
        XCTAssertEqual(StringOrInt.string("").stringValue, "")
    }

    // MARK: - Decoding

    func testDecode_fromStringJSON() throws {
        let json = #""hello world""#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)

        if case .string(let value) = decoded {
            XCTAssertEqual(value, "hello world")
        } else {
            XCTFail("Expected .string case, got \(decoded)")
        }
    }

    func testDecode_fromIntJSON() throws {
        let json = "12345".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)

        if case .int(let value) = decoded {
            XCTAssertEqual(value, 12345)
        } else {
            XCTFail("Expected .int case, got \(decoded)")
        }
    }

    func testDecode_fromZeroIntJSON() throws {
        let json = "0".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)

        if case .int(let value) = decoded {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected .int case, got \(decoded)")
        }
    }

    func testDecode_fromNegativeIntJSON() throws {
        let json = "-42".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)

        if case .int(let value) = decoded {
            XCTAssertEqual(value, -42)
        } else {
            XCTFail("Expected .int case, got \(decoded)")
        }
    }

    func testDecode_fromInvalidJSON_throwsError() {
        let json = "true".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(StringOrInt.self, from: json))
    }

    func testDecode_fromNullJSON_throwsError() {
        let json = "null".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(StringOrInt.self, from: json))
    }

    // MARK: - Encoding

    func testEncode_stringCase() throws {
        let value = StringOrInt.string("test-token")
        let encoded = try JSONEncoder().encode(value)
        let jsonString = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(jsonString, #""test-token""#)
    }

    func testEncode_intCase() throws {
        let value = StringOrInt.int(777)
        let encoded = try JSONEncoder().encode(value)
        let jsonString = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(jsonString, "777")
    }

    // MARK: - Round-trip

    func testRoundTrip_stringValue() throws {
        let original = StringOrInt.string("round-trip-token")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: encoded)

        if case .string(let value) = decoded {
            XCTAssertEqual(value, "round-trip-token")
        } else {
            XCTFail("Expected .string case after round-trip")
        }
    }

    func testRoundTrip_intValue() throws {
        let original = StringOrInt.int(98765)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: encoded)

        if case .int(let value) = decoded {
            XCTAssertEqual(value, 98765)
        } else {
            XCTFail("Expected .int case after round-trip")
        }
    }

    // MARK: - stringValue after decode

    func testStringValue_afterDecodeFromString() throws {
        let json = #""TOKEN_XYZ""#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)
        XCTAssertEqual(decoded.stringValue, "TOKEN_XYZ")
    }

    func testStringValue_afterDecodeFromInt() throws {
        let json = "100".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrInt.self, from: json)
        XCTAssertEqual(decoded.stringValue, "100")
    }
}
