//
//  SdkVersionTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

// MARK: - Fake CleverTap Core classes, looked up by name like the real one

@objc(ZeroPiiFakeCleverTap)
final class FakeCleverTap: NSObject {
    static var instanceAvailable = true
    static var recordedVersions: [String: Int32] = [:]
    static var setCallCount = 0
    private static let instance = FakeCleverTap()

    @objc class func sharedInstance() -> FakeCleverTap? {
        return instanceAvailable ? instance : nil
    }

    @objc(setCustomSdkVersion:version:)
    func setCustomSdkVersion(_ name: String, version: Int32) {
        FakeCleverTap.setCallCount += 1
        FakeCleverTap.recordedVersions[name] = version
    }

    static func reset() {
        instanceAvailable = true
        recordedVersions = [:]
        setCallCount = 0
    }
}

/// Core without setCustomSdkVersion:version:, like an older Core release.
@objc(ZeroPiiFakeOldCleverTap)
final class FakeOldCleverTap: NSObject {
    private static let instance = FakeOldCleverTap()

    @objc class func sharedInstance() -> FakeOldCleverTap? {
        return instance
    }
}

/// Class with the right name shape but no sharedInstance.
@objc(ZeroPiiFakeNoSharedInstance)
final class FakeNoSharedInstance: NSObject {}

final class SdkVersionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FakeCleverTap.reset()
    }

    func testSdkVersion_constants() {
        XCTAssertEqual(SdkVersion.name, "ZeroPii")
        XCTAssertEqual(SdkVersion.version, 10000)
    }

    // MARK: - Registration

    func testRegister_setsVersionOnCore() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap", version: 10203)

        XCTAssertTrue(registrar.registerIfNeeded())
        XCTAssertTrue(registrar.isRegistered)
        XCTAssertEqual(FakeCleverTap.recordedVersions, ["ZeroPii": 10203])
    }

    func testRegister_usesDefaultNameAndVersion() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        registrar.registerIfNeeded()

        XCTAssertEqual(FakeCleverTap.recordedVersions[SdkVersion.name], SdkVersion.version)
    }

    func testRegister_onlyCallsCoreOnce() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        registrar.registerIfNeeded()
        registrar.registerIfNeeded()
        registrar.registerIfNeeded()

        XCTAssertEqual(FakeCleverTap.setCallCount, 1)
    }

    func testRegister_laterCallRegistersAfterNilSharedInstance() {
        FakeCleverTap.instanceAvailable = false
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        XCTAssertFalse(registrar.registerIfNeeded())
        XCTAssertFalse(registrar.isRegistered)
        XCTAssertEqual(FakeCleverTap.setCallCount, 0)

        FakeCleverTap.instanceAvailable = true
        XCTAssertTrue(registrar.registerIfNeeded())
        XCTAssertEqual(FakeCleverTap.setCallCount, 1)
    }

    func testRegister_skipsWhenCoreIsMissing() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiClassThatDoesNotExist")

        XCTAssertFalse(registrar.registerIfNeeded())
        XCTAssertFalse(registrar.isRegistered)
    }

    func testRegister_skipsWhenCoreHasNoSharedInstance() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeNoSharedInstance")

        XCTAssertFalse(registrar.registerIfNeeded())
    }

    func testRegister_skipsWhenCoreIsTooOld() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeOldCleverTap")

        XCTAssertFalse(registrar.registerIfNeeded())
        XCTAssertFalse(registrar.isRegistered)
    }

    func testRegister_isSafeFromManyThreads() {
        let registrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        DispatchQueue.concurrentPerform(iterations: 50) { _ in
            registrar.registerIfNeeded()
        }

        XCTAssertEqual(FakeCleverTap.setCallCount, 1)
    }

    func testRegister_withoutCoreLinked_realClassNameIsMissing() {
        // The test host does not link CleverTap Core, so the default lookup must fail gracefully.
        let registrar = CoreSdkVersionRegistrar()

        XCTAssertFalse(registrar.registerIfNeeded())
    }

    // MARK: - ZeroPiiSDK.initialize

    // ZeroPiiSDK is a singleton that cannot be reset, so each test swaps in its own registrar
    // and calls initialize again, which is the path every later initialize call takes.

    @discardableResult
    private func initializeSDK() -> ZeroPiiSDK {
        return ZeroPiiSDK.initialize(tokenProvider: MockAccessTokenProvider(token: "test-token"),
                                     apiUrl: "https://api.test.com")
    }

    func testInitialize_createsRegistrar() {
        let sdk = initializeSDK()

        XCTAssertNotNil(sdk.coreSdkVersionRegistrar)
    }

    func testInitialize_registersVersionWithCore() {
        let sdk = initializeSDK()
        sdk.coreSdkVersionRegistrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        initializeSDK()

        XCTAssertTrue(sdk.coreSdkVersionRegistrar.isRegistered)
        XCTAssertEqual(FakeCleverTap.recordedVersions, ["ZeroPii": 10000])
    }

    func testInitialize_laterCallRegistersWhenCoreWasNotReady() {
        FakeCleverTap.instanceAvailable = false
        let sdk = initializeSDK()
        sdk.coreSdkVersionRegistrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        initializeSDK()
        XCTAssertFalse(sdk.coreSdkVersionRegistrar.isRegistered)
        XCTAssertEqual(FakeCleverTap.setCallCount, 0)

        FakeCleverTap.instanceAvailable = true
        initializeSDK()
        XCTAssertTrue(sdk.coreSdkVersionRegistrar.isRegistered)
        XCTAssertEqual(FakeCleverTap.recordedVersions, ["ZeroPii": 10000])
    }

    func testInitialize_repeatedCallsRegisterOnce() {
        let sdk = initializeSDK()
        sdk.coreSdkVersionRegistrar = CoreSdkVersionRegistrar(coreClassName: "ZeroPiiFakeCleverTap")

        initializeSDK()
        initializeSDK()
        initializeSDK()

        XCTAssertEqual(FakeCleverTap.setCallCount, 1)
    }

    func testInitialize_withoutCoreLinked_doesNotRegister() {
        let sdk = initializeSDK()
        sdk.coreSdkVersionRegistrar = CoreSdkVersionRegistrar()

        let again = initializeSDK()

        XCTAssertTrue(again === sdk)
        XCTAssertFalse(sdk.coreSdkVersionRegistrar.isRegistered)
    }
}
