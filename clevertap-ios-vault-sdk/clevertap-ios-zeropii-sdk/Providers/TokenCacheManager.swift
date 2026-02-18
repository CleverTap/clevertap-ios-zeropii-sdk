//
//  TokenCacheManager.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 08/07/25.
//

import Foundation

class TokenCacheManager: CacheProvider {
    private let enabled: Bool
    private let queue = DispatchQueue(label: "com.clevertap.ZeroPiiTokenCacheQueue", attributes: .concurrent)
    private let preferenceManager: ZeroPiiPreferenceManager?

    // In-memory map only used for write-through during tokenization session
    // This is NOT loaded from preferences on init
    private var valueToTokenMap = [String: (token: String, dataType: String)]()

    init(enabled: Bool, preferenceManager: ZeroPiiPreferenceManager? = nil) {
        self.enabled = enabled
        self.preferenceManager = preferenceManager
        // No loading from preferences on init — maps stay empty in memory
    }

    func getToken(for value: String) -> (token: String, dataType: String)? {
        guard enabled else { return nil }

        // First check in-memory cache (current session)
        let inMemory: (token: String, dataType: String)? = queue.sync { valueToTokenMap[value] }
        if let result = inMemory {
            return result
        }

        // Fall back to encrypted preferences lookup
        return preferenceManager?.lookupToken(for: value)
    }

    func putToken(value: String, token: String, dataType: String?) {
        guard enabled else { return }

        queue.async(flags: .barrier) {
            let actualDataType = dataType ?? "string"
            self.valueToTokenMap[value] = (token, actualDataType)
            self.preferenceManager?.saveValueToTokenMap(self.valueToTokenMap)
        }
    }

    func isEnabled() -> Bool {
        return enabled
    }

    func size() -> Int {
        guard enabled else { return 0 }

        return queue.sync { valueToTokenMap.count }
    }

    func clear() {
        guard enabled else { return }

        queue.async(flags: .barrier) {
            self.valueToTokenMap.removeAll()
            self.preferenceManager?.clear()
        }
    }


}
