//
//  BatchTokenModels.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Represents the result for an individual item in a batch tokenization operation.
struct BatchTokenItem {
    
    /// The original value that was tokenized.
    public let originalValue: String
    
    /// The generated token corresponding to the original value.
    public let token: String
    
    /// Indicates whether the token already existed before this operation.
    public let exists: Bool
    
    /// Indicates whether the token was newly created during this operation.
    public let newlyCreated: Bool
    
    /// The data type of the token (e.g., "string" or "number"). May be `nil` if unknown.
    public let dataType: String?
    
    public init(originalValue: String, token: String, exists: Bool, newlyCreated: Bool, dataType: String?) {
        self.originalValue = originalValue
        self.token = token
        self.exists = exists
        self.newlyCreated = newlyCreated
        self.dataType = dataType
    }
}

/// Summary statistics for a batch tokenization operation.
struct BatchTokenizeSummary {
    
    /// The total number of items processed in the batch.
    public let processedCount: Int
    
    /// The number of tokens that already existed prior to this batch operation.
    public let existingCount: Int
    
    /// The number of tokens that were newly created during this batch operation.
    public let newlyCreatedCount: Int
    
    public init(processedCount: Int, existingCount: Int, newlyCreatedCount: Int) {
        self.processedCount = processedCount
        self.existingCount = existingCount
        self.newlyCreatedCount = newlyCreatedCount
    }
}

/// Represents the result for an individual item in a batch detokenization operation.
struct BatchDetokenItem {
    
    /// The token that was detokenized.
    public let token: String
    
    /// The original value retrieved from the token. May be `nil` if not found.
    public let value: String?
    
    /// Indicates whether the token was found during detokenization.
    public let exists: Bool
    
    /// The data type of the original value (e.g., "string" or "number"). May be `nil` if unknown.
    public let dataType: String?
    
    public init(token: String, value: String?, exists: Bool, dataType: String?) {
        self.token = token
        self.value = value
        self.exists = exists
        self.dataType = dataType
    }
}

/// Summary statistics for a batch detokenization operation.
struct BatchDetokenizeSummary {
    
    /// The total number of tokens processed in the batch.
    public let processedCount: Int
    
    /// The number of tokens successfully found and detokenized.
    public let foundCount: Int
    
    /// The number of tokens that were not found during detokenization.
    public let notFoundCount: Int
    
    public init(processedCount: Int, foundCount: Int, notFoundCount: Int) {
        self.processedCount = processedCount
        self.foundCount = foundCount
        self.notFoundCount = notFoundCount
    }
}

