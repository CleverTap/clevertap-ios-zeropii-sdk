//
//  EncryptionManager.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation
import CryptoKit

public class EncryptionManager {
    private let enabled: Bool
    private let logger: ZeroPiiLogger
    private let networkEncryptionManager: NetworkEncryptionManager

    init(enabled: Bool, logger: ZeroPiiLogger) {
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
    
    // MARK: - At-Rest Encryption (with external key)

    /// Encrypts data using a provided symmetric key for at-rest storage.
    /// Returns the encrypted payload (base64) and IV (base64), or nil on failure.
    func encryptData(_ data: Data, using key: SymmetricKey) -> (encryptedPayload: String, iv: String)? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            do {
                let nonce = AES.GCM.Nonce()
                let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
                let combinedData = sealedBox.ciphertext + sealedBox.tag
                return (encryptedPayload: combinedData.base64EncodedString(), iv: Data(nonce).base64EncodedString())
            } catch {
                logger.error("At-rest encryption error: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                return nil
            }
        }
        return nil
    }

    /// Decrypts data using a provided symmetric key for at-rest storage.
    /// Takes base64-encoded encrypted payload and IV, returns the decrypted Data or nil on failure.
    func decryptData(encryptedPayload: String, iv: String, using key: SymmetricKey) -> Data? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            guard let encryptedData = Data(base64Encoded: encryptedPayload),
                  let ivData = Data(base64Encoded: iv) else {
                logger.error("At-rest decryption failed: invalid base64 input", file: #file, function: #function, line: #line)
                return nil
            }
            do {
                let nonce = try AES.GCM.Nonce(data: ivData)
                let sealedBox = try AES.GCM.SealedBox(
                    nonce: nonce,
                    ciphertext: encryptedData.dropLast(16),
                    tag: encryptedData.suffix(16)
                )
                return try AES.GCM.open(sealedBox, using: key)
            } catch {
                logger.error("At-rest decryption error: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                return nil
            }
        }
        return nil
    }

    // MARK: - Network Encrypted Request

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
