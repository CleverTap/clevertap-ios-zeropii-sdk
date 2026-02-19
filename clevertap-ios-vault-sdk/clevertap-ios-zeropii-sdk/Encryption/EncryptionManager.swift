//
//  EncryptionManager.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation

public class EncryptionManager {
    private let enabled: Bool
    private let logger: ZeroPiiLogger
    private let networkEncryptionManager: NetworkEncryptionManager

    init(enabled: Bool, logger: ZeroPiiLogger) {
        self.enabled = enabled
        self.logger = logger
        self.networkEncryptionManager = NetworkEncryptionManager()
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
    
    // MARK: - Network Encrypted Request

    func createEncryptedRequest<T: Encodable>(_ request: T) -> EncryptedRequest? {
        do {
            let dataToEncrypt: Data
            if let stringValue = request as? String {
                dataToEncrypt = Data(stringValue.utf8)
            } else {
                dataToEncrypt = try JSONEncoder().encode(request)
            }
            logger.debug("Request before encryption: \(dataToEncrypt)", file: #file, line: #line)
            
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
                logger.error("Encryption failed: \(encryptionResult)", file: #file, line: #line)
                return nil
            }
        } catch {
            let errorMessage = "Encryption error: \(error.localizedDescription)"
            logger.error(errorMessage, file: #file, line: #line)
            return nil
        }
    }

}
