//
//  EncryptionResult.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation

/// Enum representing the result of an encryption operation
enum EncryptionResult {
    /// Successful encryption
    case success(encryptedPayload: String, sessionKey: String, iv: String)
    /// Failed encryption with an error message
    case failure(message: String)
}

/// Enum representing the result of a decryption operation
enum DecryptionResult {
    /// Successful decryption
    case success(data: Data)
    /// Failed decryption with an error message
    case failure(message: String)
}
