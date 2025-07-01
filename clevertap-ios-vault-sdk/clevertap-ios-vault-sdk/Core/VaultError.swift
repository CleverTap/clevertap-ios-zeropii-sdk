//
//  VaultError.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

enum VaultError: Int, Error {
    
    case authenticationFailed = 1000
    
    // MARK: - Localized Error Description
    public var errorDescription: String? {
        switch self {
            case .authenticationFailed:
                return "Authentication failed error."
        }
    }
}
