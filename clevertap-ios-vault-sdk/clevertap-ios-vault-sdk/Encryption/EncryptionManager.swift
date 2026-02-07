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
    func encrypt(data: Data) -> EncryptionResult {
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
    
    func createEncryptedRequest<T: Encodable>(_ request: T) -> EncryptedRequest? {
        do {
            let dataToEncrypt: Data
            if let stringValue = request as? String {
                dataToEncrypt = Data(stringValue.utf8)
            } else {
                dataToEncrypt = try JSONEncoder().encode(request)
            }
            logger.debug("Request before encryption: \(dataToEncrypt)", file: #file, function: #function, line: #line)
            
            // Perform encryption
            let encryptionResult = encrypt(data: dataToEncrypt)
            
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
        } catch {
            let errorMessage = "Encryption error: \(error.localizedDescription)"
            logger.error(errorMessage, file: #file, function: #function, line: #line)
            return nil
        }
    }

}
