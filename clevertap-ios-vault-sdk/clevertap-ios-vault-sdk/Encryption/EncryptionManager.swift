//
//  EncryptionManager.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation

public class EncryptionManager {
    private let enabled: Bool
    private let logger: VaultLogger
    private let networkEncryptionManager: NetworkEncryptionManager

    init(enabled: Bool, logger: VaultLogger) {
        self.enabled = enabled
        self.logger = logger
        self.networkEncryptionManager = NetworkEncryptionManager()
    }

    /// Checks if encryption is enabled
    func isEnabled() -> Bool {
        return enabled
    }

    /// Encrypts the provided data
    func encrypt(data: String) -> EncryptionResult {
        guard enabled else {
            return .failure(message: "Encryption is disabled")
        }

        return networkEncryptionManager.encrypt(data: data)
    }

    /// Decrypts the provided data
    func decrypt(encryptedPayload: String, iv: String) -> DecryptionResult {
        guard enabled else {
            return .failure(message: "Encryption is disabled")
        }
        
        return networkEncryptionManager.decrypt(encryptedPayload: encryptedPayload, iv: iv)
    }
}
