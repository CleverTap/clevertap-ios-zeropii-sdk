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
    case batchTokenisationFalied = 1007
    case invalidBatchTokenisationResponse = 1008
    case batchDetokenisationFalied = 1009
    case invalidBatchDetokenisationResponse = 1010
    case invalidBaseURL = 1011
    case jsonParsingError = 1012
    case serverError = 1013
    case authRequestError = 1014
    case buildRequestError = 1015
    
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
        case .batchTokenisationFalied:
            return "Batch tokenisation failed error."
        case .invalidBatchTokenisationResponse:
            return "Invalid batch tokenization response type."
        case .batchDetokenisationFalied:
            return "Batch detokenisation failed error."
        case .invalidBatchDetokenisationResponse:
            return "Invalid batch detokenization response type."
        case .invalidBaseURL:
            return "Invalid Auth base URL"
        case .jsonParsingError:
            return "Failed to parse JSON"
        case .serverError:
            return "Server error"
        case .authRequestError:
            return "Failed to build auth request"
        case .buildRequestError:
            return "Failed to build request"
        }
    }
}
