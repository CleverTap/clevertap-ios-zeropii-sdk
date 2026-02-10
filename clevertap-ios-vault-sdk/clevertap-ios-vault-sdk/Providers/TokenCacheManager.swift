//
//  TokenCacheManager.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 08/07/25.
//

import Foundation

class TokenCacheManager: CacheProvider {
    private let enabled: Bool
    private let queue = DispatchQueue(label: "com.clevertap.VaultTokenCacheQueue", attributes: .concurrent)
    private let preferenceManager: VaultPreferenceManager?

    // In-memory maps only used for write-through during tokenization session
    // These are NOT loaded from preferences on init
    private var tokenToValueMap = [String: (value: String, dataType: String)]()
    private var valueToTokenMap = [String: (token: String, dataType: String)]()

    init(enabled: Bool, preferenceManager: VaultPreferenceManager? = nil) {
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

    func getValue(for token: String) -> (value: String, dataType: String)? {
        guard enabled else { return nil }

        // Read directly from encrypted preferences (no in-memory cache for detokenization)
        // This decrypts the whole map, finds the token, then decrypts the individual value
        return preferenceManager?.lookupValue(for: token)
    }

    func putValue(token: String, value: String, dataType: String?) {
        guard enabled else { return }

        queue.async(flags: .barrier) {
            let actualDataType = dataType ?? "string"
            self.tokenToValueMap[token] = (value, actualDataType)
            self.preferenceManager?.saveTokenToValueMap(self.tokenToValueMap)
        }
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

        return queue.sync { tokenToValueMap.count }
    }

    func clear() {
        guard enabled else { return }

        queue.async(flags: .barrier) {
            self.tokenToValueMap.removeAll()
            self.valueToTokenMap.removeAll()
            self.preferenceManager?.clear()
        }
    }


}
