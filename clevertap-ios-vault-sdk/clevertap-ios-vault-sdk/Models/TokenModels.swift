//
//  TokenModels.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Authentication token response model returned from auth API.
struct AuthTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshExpiresIn: Int
    let tokenType: String
    let scope: String
}

/// Request model for tokenizing a single value.
struct TokenizeRequest: Codable {
    let value: String
}

/// Response model for tokenizing a single value.
struct TokenizeResponse: Codable {
    let token: String
    let exists: Bool
    let newlyCreated: Bool
    let dataType: String?
}

/// Request model for detokenizing a single token.
struct DetokenizeRequest: Codable {
    let token: String
}

/// Response model for detokenizing a single token.
struct DetokenizeResponse: Codable {
    let value: String?
    let exists: Bool
    let dataType: String?
}

/// Request model for batch tokenization.
struct BatchTokenizeRequest: Codable {
    let values: [String]
}

/// Response model for batch tokenization.
struct BatchTokenizeResponse: Codable {
    let results: [BatchTokenItem]
    let summary: BatchTokenizeSummary
}

/// Request model for batch detokenization.
struct BatchDetokenizeRequest: Codable {
    let tokens: [String]
}

/// Response model for batch detokenization.
struct BatchDetokenizeResponse: Codable {
    let results: [BatchDetokenItem]
    let summary: BatchDetokenizeSummary
}

/// Represents the result for an individual item in a batch tokenization operation.
struct BatchTokenItem: Codable {
    let originalValue: String
    let token: String
    let exists: Bool
    let newlyCreated: Bool
    let dataType: String?
}

/// Summary statistics for a batch tokenization operation.
struct BatchTokenizeSummary: Codable {
    let processedCount: Int
    let existingCount: Int
    let newlyCreatedCount: Int
}

/// Represents the result for an individual item in a batch detokenization operation.
struct BatchDetokenItem: Codable {
    let token: String
    let value: String?
    let exists: Bool
    let dataType: String?
}

/// Summary statistics for a batch detokenization operation.
struct BatchDetokenizeSummary: Codable {
    let processedCount: Int
    let foundCount: Int
    let notFoundCount: Int
}
