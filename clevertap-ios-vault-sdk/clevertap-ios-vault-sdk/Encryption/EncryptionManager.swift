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
    
    func createEncryptedRequest(_ request: Any) -> EncryptedRequest? {
        // Convert request object to JSON
        guard let requestData = try? JSONSerialization.data(withJSONObject: request, options: []),
              let requestJson = String(data: requestData, encoding: .utf8) else {
            logger.error("Failed to serialize request to JSON", file: #file, function: #function, line: #line)
            return nil
        }
        
        logger.debug("Request before encryption: \(requestJson)", file: #file, function: #function, line: #line)
        
        // Perform encryption
        let encryptionResult = encrypt(data: requestJson)
        
        switch encryptionResult {
        case .success(let encryptedPayload, let sessionKey, let iv):
            return EncryptedRequest(
                itp: encryptedPayload,
                itk: sessionKey,
                itv: iv
            )
        default:
            logger.error("Encryption failed: \(encryptionResult)", file: #file, function: #function, line: #line)
            return nil
        }
    }

}
