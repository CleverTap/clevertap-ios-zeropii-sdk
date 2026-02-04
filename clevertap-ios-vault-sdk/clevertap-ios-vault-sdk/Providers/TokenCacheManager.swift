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
    
    // In-memory token-to-value and value-to-token maps
    private var tokenToValueMap = [String: (value: String, dataType: String)]()
    private var valueToTokenMap = [String: (token: String, dataType: String)]()
    
    init(enabled: Bool) {
        self.enabled = enabled
    }
    
    func getToken(for value: String) -> (token: String, dataType: String)? {
        guard enabled else { return nil }

        return queue.sync { valueToTokenMap[value] }
    }
    
    func getValue(for token: String) -> (value: String, dataType: String)? {
        guard enabled else { return nil }
                
        return queue.sync { tokenToValueMap[token] }
    }
    
    func putValue(token: String, value: String, dataType: String?) {
        guard enabled else { return }
                
        queue.async(flags: .barrier) {
            let actualDataType = dataType ?? "string"
            self.tokenToValueMap[token] = (value, actualDataType)
        }
    }
    
    func putToken(value: String, token: String, dataType: String?) {
        guard enabled else { return }
        
        queue.async(flags: .barrier) {
            let actualDataType = dataType ?? "string"
            self.valueToTokenMap[value] = (token, actualDataType)
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
        }
    }
    
    
}
