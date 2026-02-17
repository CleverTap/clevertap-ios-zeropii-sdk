//
//  ZeroPiiPreferenceManager.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 10/02/26.
//

import Foundation
import CryptoKit

class ZeroPiiPreferenceManager {

    // MARK: - Constants
    private static let tokenToValueMapKey = "zeropii_token_to_value_map"
    private static let tokenToValueIVKey = "zeropii_token_to_value_iv"
    private static let valueToTokenMapKey = "zeropii_value_to_token_map"
    private static let valueToTokenIVKey = "zeropii_value_to_token_iv"
    private static let encryptionKeyKeychainKey = "zeropii_preference_encryption_key"

    // MARK: - Dependencies
    private let keychainManager: KeychainManager
    private let encryptionManager: EncryptionManager
    private let logger: ZeroPiiLogger
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.clevertap.ZeroPiiPreferenceQueue", attributes: .concurrent)

    // MARK: - Encryption Key
    private var encryptionKey: SymmetricKey?

    // MARK: - Initialization
    init(keychainManager: KeychainManager, encryptionManager: EncryptionManager, logger: ZeroPiiLogger = ZeroPiiLogger.shared, defaults: UserDefaults = .standard) {
        self.keychainManager = keychainManager
        self.encryptionManager = encryptionManager
        self.logger = logger
        self.defaults = defaults
        self.encryptionKey = loadOrGenerateEncryptionKey()
    }

    // MARK: - Key Management

    private func loadOrGenerateEncryptionKey() -> SymmetricKey {
        if let keyData = keychainManager.getData(forKey: ZeroPiiPreferenceManager.encryptionKeyKeychainKey) {
            logger.debug("Loaded preference encryption key from Keychain", file: #file, line: #line)
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        keychainManager.setData(keyData, forKey: ZeroPiiPreferenceManager.encryptionKeyKeychainKey)
        logger.debug("Generated and stored new preference encryption key", file: #file, line: #line)
        return newKey
    }

    // MARK: - Save Methods

    /// Saves the token-to-value map with double-layer encryption:
    /// 1. Each value (sensitive data + dataType) is individually encrypted
    /// 2. The entire map is encrypted before persisting to UserDefaults
    func saveTokenToValueMap(_ map: [String: (value: String, dataType: String)]) {
        queue.async(flags: .barrier) {
            guard let key = self.encryptionKey else {
                self.logger.error("No encryption key available for saving token-to-value map", file: #file, line: #line)
                return
            }

            var serializable = [String: [String: String]]()
            for (token, tuple) in map {
                // Encrypt individual value
                guard let encryptedValue = self.encryptValue(tuple.value, using: key),
                      let encryptedDataType = self.encryptValue(tuple.dataType, using: key) else {
                    self.logger.error("Failed to encrypt individual value for token", file: #file, line: #line)
                    continue
                }
                serializable[token] = [
                    "ev": encryptedValue.payload,
                    "eiv": encryptedValue.iv,
                    "edt": encryptedDataType.payload,
                    "edtiv": encryptedDataType.iv
                ]
            }
            self.encryptAndPersist(serializable, mapKey: ZeroPiiPreferenceManager.tokenToValueMapKey, ivKey: ZeroPiiPreferenceManager.tokenToValueIVKey)
        }
    }

    /// Saves the value-to-token map with double-layer encryption:
    /// 1. Each value (sensitive original value used as key) is individually encrypted
    /// 2. The entire map is encrypted before persisting to UserDefaults
    func saveValueToTokenMap(_ map: [String: (token: String, dataType: String)]) {
        queue.async(flags: .barrier) {
            guard let key = self.encryptionKey else {
                self.logger.error("No encryption key available for saving value-to-token map", file: #file, line: #line)
                return
            }

            var serializable = [String: [String: String]]()
            for (value, tuple) in map {
                // Encrypt the sensitive value used as key
                guard let encryptedKey = self.encryptValue(value, using: key) else {
                    self.logger.error("Failed to encrypt map key for value-to-token map", file: #file, line: #line)
                    continue
                }
                // Token stays as-is; encrypt dataType
                guard let encryptedDataType = self.encryptValue(tuple.dataType, using: key) else {
                    self.logger.error("Failed to encrypt dataType for value-to-token map", file: #file, line: #line)
                    continue
                }
                // Use encrypted key as the map key to protect PII
                let encryptedKeyId = encryptedKey.payload + "|" + encryptedKey.iv
                serializable[encryptedKeyId] = [
                    "token": tuple.token,
                    "edt": encryptedDataType.payload,
                    "edtiv": encryptedDataType.iv,
                    "ov": encryptedKey.payload,
                    "oiv": encryptedKey.iv
                ]
            }
            self.encryptAndPersist(serializable, mapKey: ZeroPiiPreferenceManager.valueToTokenMapKey, ivKey: ZeroPiiPreferenceManager.valueToTokenIVKey)
        }
    }

    // MARK: - Lookup Methods (Read from preferences, no in-memory cache)

    /// Looks up a token in the persisted token-to-value map:
    /// 1. Decrypts the whole map from UserDefaults
    /// 2. Finds the token key
    /// 3. Decrypts the individual value and dataType
    /// Returns the decrypted value and dataType, or nil if not found
    func lookupValue(for token: String) -> (value: String, dataType: String)? {
        return queue.sync {
            guard let key = encryptionKey else {
                logger.error("No encryption key available for lookup", file: #file, line: #line)
                return nil
            }

            // Step 1: Decrypt the whole map from preferences
            guard let serializable: [String: [String: String]] = loadAndDecryptMap(
                mapKey: ZeroPiiPreferenceManager.tokenToValueMapKey,
                ivKey: ZeroPiiPreferenceManager.tokenToValueIVKey
            ) else {
                return nil
            }

            // Step 2: Find the token key (tokens are stored as plaintext keys)
            guard let entry = serializable[token] else {
                logger.debug("Token not found in persisted map", file: #file, line: #line)
                return nil
            }

            // Step 3: Decrypt individual value and dataType
            guard let evPayload = entry["ev"],
                  let evIV = entry["eiv"],
                  let edtPayload = entry["edt"],
                  let edtIV = entry["edtiv"] else {
                logger.error("Malformed entry in token-to-value map", file: #file, line: #line)
                return nil
            }

            guard let decryptedValue = decryptValue(payload: evPayload, iv: evIV, using: key),
                  let decryptedDataType = decryptValue(payload: edtPayload, iv: edtIV, using: key) else {
                logger.error("Failed to decrypt individual value for token", file: #file, line: #line)
                return nil
            }

            return (value: decryptedValue, dataType: decryptedDataType)
        }
    }

    /// Looks up a value in the persisted value-to-token map:
    /// 1. Decrypts the whole map from UserDefaults
    /// 2. Iterates entries, decrypts each original value, and compares
    /// 3. Returns the token and decrypted dataType, or nil if not found
    func lookupToken(for value: String) -> (token: String, dataType: String)? {
        return queue.sync {
            guard let key = encryptionKey else {
                logger.error("No encryption key available for lookup", file: #file, line: #line)
                return nil
            }

            // Step 1: Decrypt the whole map from preferences
            guard let serializable: [String: [String: String]] = loadAndDecryptMap(
                mapKey: ZeroPiiPreferenceManager.valueToTokenMapKey,
                ivKey: ZeroPiiPreferenceManager.valueToTokenIVKey
            ) else {
                return nil
            }

            // Step 2: Iterate and decrypt each original value to find match
            for (_, entry) in serializable {
                guard let ovPayload = entry["ov"],
                      let ovIV = entry["oiv"],
                      let token = entry["token"],
                      let edtPayload = entry["edt"],
                      let edtIV = entry["edtiv"] else {
                    continue
                }

                guard let decryptedOriginalValue = decryptValue(payload: ovPayload, iv: ovIV, using: key) else {
                    continue
                }

                if decryptedOriginalValue == value {
                    guard let decryptedDataType = decryptValue(payload: edtPayload, iv: edtIV, using: key) else {
                        continue
                    }
                    return (token: token, dataType: decryptedDataType)
                }
            }

            logger.debug("Value not found in persisted value-to-token map", file: #file, line: #line)
            return nil
        }
    }

    // MARK: - Clear

    func clear() {
        queue.async(flags: .barrier) {
            self.defaults.removeObject(forKey: ZeroPiiPreferenceManager.tokenToValueMapKey)
            self.defaults.removeObject(forKey: ZeroPiiPreferenceManager.tokenToValueIVKey)
            self.defaults.removeObject(forKey: ZeroPiiPreferenceManager.valueToTokenMapKey)
            self.defaults.removeObject(forKey: ZeroPiiPreferenceManager.valueToTokenIVKey)
            self.logger.debug("Cleared preference maps", file: #file, line: #line)
        }
    }

    // MARK: - Private Helpers (Individual Value Encryption)

    private func encryptValue(_ value: String, using key: SymmetricKey) -> (payload: String, iv: String)? {
        let data = Data(value.utf8)
        guard let encrypted = encryptionManager.encryptData(data, using: key) else {
            return nil
        }
        return (payload: encrypted.encryptedPayload, iv: encrypted.iv)
    }

    private func decryptValue(payload: String, iv: String, using key: SymmetricKey) -> String? {
        guard let decryptedData = encryptionManager.decryptData(encryptedPayload: payload, iv: iv, using: key) else {
            return nil
        }
        return String(data: decryptedData, encoding: .utf8)
    }

    // MARK: - Private Helpers (Whole Map Encryption)

    private func encryptAndPersist(_ serializable: [String: [String: String]], mapKey: String, ivKey: String) {
        guard let key = encryptionKey else {
            logger.error("No encryption key available for preference persistence", file: #file, line: #line)
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: serializable, options: [])

            guard let encrypted = encryptionManager.encryptData(jsonData, using: key) else {
                logger.error("Failed to encrypt map for key: \(mapKey)", file: #file, line: #line)
                return
            }

            defaults.set(encrypted.encryptedPayload, forKey: mapKey)
            defaults.set(encrypted.iv, forKey: ivKey)
            logger.debug("Persisted encrypted map for key: \(mapKey)", file: #file, line: #line)
        } catch {
            logger.error("Failed to serialize map for key \(mapKey): \(error.localizedDescription)", file: #file, line: #line)
        }
    }

    private func loadAndDecryptMap<T>(mapKey: String, ivKey: String) -> T? where T: Any {
        guard let key = encryptionKey else {
            logger.error("No encryption key available for preference loading", file: #file, line: #line)
            return nil
        }

        guard let encryptedPayload = defaults.string(forKey: mapKey),
              let iv = defaults.string(forKey: ivKey) else {
            return nil
        }

        guard let decryptedData = encryptionManager.decryptData(encryptedPayload: encryptedPayload, iv: iv, using: key) else {
            logger.error("Failed to decrypt preference map for key: \(mapKey)", file: #file, line: #line)
            return nil
        }

        do {
            let deserialized = try JSONSerialization.jsonObject(with: decryptedData, options: [])
            return deserialized as? T
        } catch {
            logger.error("Failed to deserialize map for key \(mapKey): \(error.localizedDescription)", file: #file, line: #line)
            return nil
        }
    }
}
