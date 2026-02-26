//
//  EncryptionManagerTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class EncryptionManagerTests: XCTestCase {

    private var encryptionManager: EncryptionManager!

    override func setUpWithError() throws {
        encryptionManager = EncryptionManager(enabled: true, logger: ZeroPiiLogger.shared)
    }

    override func tearDownWithError() throws {
        encryptionManager = nil
    }

    // MARK: - Encrypt (enabled)

    func testEncrypt_enabled_returnsSuccess() {
        let data = "Hello, World!".data(using: .utf8)!
        let result = encryptionManager.encrypt(data: data)

        if #available(iOS 13.0, tvOS 13.0, *) {
            if case .success(let itp, let itk, let itv) = result {
                XCTAssertFalse(itp.isEmpty)
                XCTAssertFalse(itk.isEmpty)
                XCTAssertFalse(itv.isEmpty)
            } else {
                XCTFail("Expected success on iOS 13+, got \(result)")
            }
        }
        // On iOS < 13, encryption returns failure – that's acceptable
    }

    func testEncrypt_enabled_producesBase64EncodedOutput() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let data = "SensitiveData".data(using: .utf8)!
        let result = encryptionManager.encrypt(data: data)

        guard case .success(let itp, let itk, let itv) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertNotNil(Data(base64Encoded: itp), "itp should be valid base64")
        XCTAssertNotNil(Data(base64Encoded: itk), "itk should be valid base64")
        XCTAssertNotNil(Data(base64Encoded: itv), "itv should be valid base64")
    }

    // MARK: - Encrypt (disabled)

    func testEncrypt_disabled_returnsFailure() {
        let disabledManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)
        let data = "test".data(using: .utf8)!

        let result = disabledManager.encrypt(data: data)

        if case .failure = result {
            // expected
        } else {
            XCTFail("Expected failure when encryption is disabled")
        }
    }

    // MARK: - Decrypt (enabled)

    func testDecrypt_enabled_roundTrip_returnsOriginalData() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let originalData = "Round trip test".data(using: .utf8)!
        let encryptResult = encryptionManager.encrypt(data: originalData)

        guard case .success(let itp, _, let itv) = encryptResult else {
            XCTFail("Encryption failed, cannot test decrypt")
            return
        }

        let decryptResult = encryptionManager.decrypt(encryptedPayload: itp, iv: itv)

        if case .success(let decryptedData) = decryptResult {
            XCTAssertEqual(decryptedData, originalData)
        } else {
            XCTFail("Expected decrypt success, got \(decryptResult)")
        }
    }

    func testDecrypt_enabled_wrongIV_returnsFailure() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let data = "test".data(using: .utf8)!
        let encryptResult = encryptionManager.encrypt(data: data)

        guard case .success(let itp, _, _) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Use wrong IV
        let wrongIV = Data(repeating: 0, count: 12).base64EncodedString()
        let decryptResult = encryptionManager.decrypt(encryptedPayload: itp, iv: wrongIV)

        if case .failure = decryptResult {
            // expected – wrong IV should fail
        } else {
            XCTFail("Expected failure with wrong IV")
        }
    }

    func testDecrypt_enabled_invalidBase64_returnsFailure() {
        let decryptResult = encryptionManager.decrypt(encryptedPayload: "not-base64!!!", iv: "also-not-base64!!!")

        if case .failure = decryptResult {
            // expected
        } else {
            XCTFail("Expected failure for invalid base64 input")
        }
    }

    // MARK: - Decrypt (disabled)

    func testDecrypt_disabled_returnsFailure() {
        let disabledManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)

        let result = disabledManager.decrypt(encryptedPayload: "payload", iv: "iv")

        if case .failure = result {
            // expected
        } else {
            XCTFail("Expected failure when encryption is disabled")
        }
    }

    // MARK: - createEncryptedRequest (enabled)

    func testCreateEncryptedRequest_enabled_returnsRequest() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let request = TokenizeRequest(value: "test@email.com")
        let encrypted = encryptionManager.createEncryptedRequest(request)

        XCTAssertNotNil(encrypted)
        XCTAssertFalse(encrypted!.itp.isEmpty)
        XCTAssertFalse(encrypted!.itk.isEmpty)
        XCTAssertFalse(encrypted!.itv.isEmpty)
    }

    func testCreateEncryptedRequest_enabled_withBatchRequest() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let batchRequest = BatchTokenizeRequest(values: ["a@test.com", "b@test.com"])
        let encrypted = encryptionManager.createEncryptedRequest(batchRequest)

        XCTAssertNotNil(encrypted)
        XCTAssertFalse(encrypted!.itp.isEmpty)
    }

    func testCreateEncryptedRequest_enabled_withStringValue() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let encrypted = encryptionManager.createEncryptedRequest("plain string value")

        XCTAssertNotNil(encrypted)
        XCTAssertFalse(encrypted!.itk.isEmpty)
    }

    func testCreateEncryptedRequest_enabled_producesDecryptablePayload() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let originalRequest = TokenizeRequest(value: "secret@email.com")
        guard let encReq = encryptionManager.createEncryptedRequest(originalRequest) else {
            XCTFail("createEncryptedRequest returned nil")
            return
        }

        let decryptResult = encryptionManager.decrypt(encryptedPayload: encReq.itp, iv: encReq.itv)
        guard case .success(let data) = decryptResult else {
            XCTFail("Failed to decrypt request payload")
            return
        }

        let decoded = try? JSONDecoder().decode(TokenizeRequest.self, from: data)
        XCTAssertEqual(decoded?.value, "secret@email.com")
    }

    // MARK: - createEncryptedRequest (disabled)

    func testCreateEncryptedRequest_disabled_returnsNil() {
        let disabledManager = EncryptionManager(enabled: false, logger: ZeroPiiLogger.shared)

        let result = disabledManager.createEncryptedRequest(TokenizeRequest(value: "test"))

        XCTAssertNil(result)
    }

    // MARK: - Session key consistency

    func testEncrypt_sameInstance_usesConsistentSessionKey() {
        guard #available(iOS 13.0, tvOS 13.0, *) else { return }

        let data1 = "data1".data(using: .utf8)!
        let data2 = "data2".data(using: .utf8)!

        let result1 = encryptionManager.encrypt(data: data1)
        let result2 = encryptionManager.encrypt(data: data2)

        guard case .success(_, let key1, _) = result1,
              case .success(_, let key2, _) = result2 else {
            XCTFail("Both encryptions should succeed")
            return
        }

        // Session key must be consistent across encryptions on the same instance
        XCTAssertEqual(key1, key2, "Session key should be the same within one EncryptionManager instance")
    }
}
