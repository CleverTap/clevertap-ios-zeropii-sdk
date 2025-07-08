//
//  VaultError.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

enum VaultError: Int, Error {
    
    case unauthorized = 401
    case authenticationFailed = 1000
    case tokenisationFalied = 1001
    case invalidTokenisationResponse = 1002
    case networkError = 1003
    case refreshTokenError = 1004
    case detokenisationFalied = 1005
    case invalidDetokenisationResponse = 1006
    
    // MARK: - Localized Error Description
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed error."
        case .tokenisationFalied:
            return "Tokenisation failed error."
        case .invalidTokenisationResponse:
            return "Invalid tokenization response type."
        case .networkError:
            return "Network error."
        case .unauthorized:
            return "Unauthorized error."
        case .refreshTokenError:
            return "Refresh token error."
        case .detokenisationFalied:
            return "Detokenisation failed error."
        case .invalidDetokenisationResponse:
            return "Invalid detokenization response type."
        }
    }
}
