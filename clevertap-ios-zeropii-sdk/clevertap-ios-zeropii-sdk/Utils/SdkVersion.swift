//
//  SdkVersion.swift
//  clevertap-ios-zeropii-sdk
//

import Foundation

/// The SDK name and version reported to CleverTap Core SDK.
enum SdkVersion {
    static let name = "ZeroPii"
    // major * 10000 + minor * 100 + patch, the format CleverTap Core SDK expects. 10000 is 1.0.0.
    static let version: Int32 = 10000
}

/// Registers the ZeroPii SDK name and version with CleverTap Core SDK through
/// `setCustomSdkVersion:version:`, so it is sent in the `af` block of Core's requests.
///
/// Core is looked up at runtime, so ZeroPii has no compile-time dependency on it and
/// keeps working when the app does not link Core.
final class CoreSdkVersionRegistrar {

    private let coreClassName: String
    private let sdkName: String
    private let version: Int32
    private let logger: ZeroPiiLoggerProtocol?
    private let lock = NSLock()
    private var registered = false

    init(
        coreClassName: String = "CleverTap",
        sdkName: String = SdkVersion.name,
        version: Int32 = SdkVersion.version,
        logger: ZeroPiiLoggerProtocol? = nil
    ) {
        self.coreClassName = coreClassName
        self.sdkName = sdkName
        self.version = version
        self.logger = logger
    }

    var isRegistered: Bool {
        lock.lock()
        defer { lock.unlock() }
        return registered
    }

    /// Registers the version with Core. Marked done only on success, so a later
    /// `ZeroPiiSDK.initialize` call can register if Core had no instance the first time.
    /// - Returns: `true` once the version has been registered.
    @discardableResult
    func registerIfNeeded() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if registered { return true }

        let sharedInstanceSelector = NSSelectorFromString("sharedInstance")
        let setCustomSdkVersionSelector = NSSelectorFromString("setCustomSdkVersion:version:")

        guard let coreClass = NSClassFromString(coreClassName),
              class_getClassMethod(coreClass, sharedInstanceSelector) != nil else {
            logger?.debug("CleverTap Core SDK not found, skipping SDK version registration", file: #file, line: #line)
            return false
        }
        guard let core = (coreClass as AnyObject).perform(sharedInstanceSelector)?.takeUnretainedValue() as? NSObject else {
            logger?.debug("CleverTap sharedInstance is nil, skipping SDK version registration", file: #file, line: #line)
            return false
        }
        guard core.responds(to: setCustomSdkVersionSelector) else {
            logger?.debug("CleverTap Core SDK does not support setCustomSdkVersion:version:, skipping SDK version registration", file: #file, line: #line)
            return false
        }

        typealias SetCustomSdkVersion = @convention(c) (AnyObject, Selector, NSString, Int32) -> Void
        let setCustomSdkVersion = unsafeBitCast(core.method(for: setCustomSdkVersionSelector), to: SetCustomSdkVersion.self)
        setCustomSdkVersion(core, setCustomSdkVersionSelector, sdkName as NSString, version)
        registered = true
        logger?.info("Registered \(sdkName) \(version) with CleverTap Core SDK", file: #file, line: #line)
        return true
    }
}
