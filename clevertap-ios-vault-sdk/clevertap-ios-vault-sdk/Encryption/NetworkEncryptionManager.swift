//
//  NetworkEncryptionManager.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation
import CryptoKit

public class NetworkEncryptionManager {
    private let logger: VaultLogger
    
    private let keyQueue = DispatchQueue(label: "com.clevertap.NetworkEncryptionManager.keyqueue")
    
    private var sessionKey: SymmetricKey?
    
    init(logger: VaultLogger = VaultLogger.shared) {
        self.logger = logger
    }
    
    private func getOrGenerateSessionKey() -> SymmetricKey {
        return keyQueue.sync {
            if let key = sessionKey {
                return key
            }
            
            let newKey = SymmetricKey(size: .bits256)
            logger.debug("Generated new session key.", file: #file, function: #function, line: #line)
            sessionKey = newKey
            return newKey
        }
    }
    
    private func sessionEncryptionKey(for key: SymmetricKey) -> String {
        let keyData = key.withUnsafeBytes { Data($0) }
        return keyData.base64EncodedString()
    }
    
    /// Encrypts data for network transmission
    func encrypt(data: String) -> EncryptionResult {
        if #available(iOS 13.0, tvOS 13.0, *) {
            do {
                guard JSONSerialization.isValidJSONObject(data),
                      let data = try? JSONSerialization.data(withJSONObject: data, options: []) else {
                    let failureMessage = "Encryption failed, invalid JSON object."
                    logger.debug(failureMessage, file: #file, function: #function, line: #line)
                    return EncryptionResult.failure(message: failureMessage)
                }
                
                let key = getOrGenerateSessionKey()
                let nonce = AES.GCM.Nonce()
                let nonceData = Data(nonce).base64EncodedString()
                let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
                
                // Combine Ciphertext + Tag because the server expects it this way
                let combinedData = sealedBox.ciphertext + sealedBox.tag
                let encryptedPayload = combinedData.base64EncodedString()
                return EncryptionResult.success(encryptedPayload: encryptedPayload, sessionKey: sessionEncryptionKey(for: key), iv: nonceData)
            }
            catch {
                let errorMessage = "Encryption in transit error: \(error.localizedDescription)"
                logger.error(errorMessage, file: #file, function: #function, line: #line)
                return EncryptionResult.failure(message: errorMessage)
            }
        } else {
            let failureMessage = "Encryption in transit is only available from iOS 13 and later."
            logger.debug(failureMessage, file: #file, function: #function, line: #line)
            return EncryptionResult.failure(message: failureMessage)
        }
    }

    /// Decrypts received data from network
    func decrypt(encryptedPayload: String, iv: String) -> DecryptionResult {
        if #available(iOS 13.0, tvOS 13.0, *) {
            guard let nonceData = Data(base64Encoded: iv),
                  let encryptedData = Data(base64Encoded: encryptedPayload)
            else {
                let failureMessage = "Decryption failed, incorrect nonce or encrypted data."
                logger.debug(failureMessage, file: #file, function: #function, line: #line)
                return DecryptionResult.failure(message: failureMessage)
            }
            do {
                logger.debug("Encrypted Response: \(encryptedPayload)", file: #file, function: #function, line: #line)
                let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData),
                                                      ciphertext: encryptedData.dropLast(16), // Excluding the tag
                                                      tag: encryptedData.suffix(16)) // Last 16 bytes are the authentication tag
                
                let decryptedData = try AES.GCM.open(sealedBox, using: getOrGenerateSessionKey())
                return DecryptionResult.success(data: decryptedData.base64EncodedString())
            } catch {
                let errorMessage = "Decryption in transit error: \(error.localizedDescription)"
                logger.error(errorMessage, file: #file, function: #function, line: #line)
                return DecryptionResult.failure(message: errorMessage)
            }
        } else {
            let failureMessage = "Decryption in transit is only available from iOS 13 and later."
            logger.debug(failureMessage, file: #file, function: #function, line: #line)
            return DecryptionResult.failure(message: failureMessage)
        }
    }
}
