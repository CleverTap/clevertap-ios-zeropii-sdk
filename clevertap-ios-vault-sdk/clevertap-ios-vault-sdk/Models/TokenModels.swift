//
//  TokenModels.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Request model for tokenizing a single value.
struct TokenizeRequest: Codable {
    let value: String
}

/// Response model for tokenizing a single value.
struct TokenizeResponse: Codable {
    let token: StringOrInt
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
@objc public class BatchTokenItem: NSObject, Codable {
    @objc public let originalValue: String
    @objc public let token: String
    @objc public let exists: Bool
    @objc public let newlyCreated: Bool
    @objc public let dataType: String?
    
    init(originalValue: String, token: String, exists: Bool, newlyCreated: Bool, dataType: String?) {
        self.originalValue = originalValue
        self.token = token
        self.exists = exists
        self.newlyCreated = newlyCreated
        self.dataType = dataType
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.originalValue = try container.decode(String.self, forKey: .originalValue)
        // token can be String or Number
        let decodedToken: String
        if let stringValue = try? container.decode(String.self, forKey: .token) {
            decodedToken = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .token) {
            decodedToken = "\(intValue)"
        } else {
            // Fallback if neither String nor number
            decodedToken = ""
        }
        self.token = decodedToken
        self.exists = try container.decode(Bool.self, forKey: .exists)
        self.newlyCreated = try container.decode(Bool.self, forKey: .newlyCreated)
        self.dataType = try container.decodeIfPresent(String.self, forKey: .dataType)
        super.init()
    }
    
    enum CodingKeys: String, CodingKey {
        case originalValue, token, exists, newlyCreated, dataType
    }
}

/// Summary statistics for a batch tokenization operation.
@objc public class BatchTokenizeSummary: NSObject, Codable {
    @objc public let processedCount: Int
    @objc public let existingCount: Int
    @objc public let newlyCreatedCount: Int
    
    @objc public init(processedCount: Int, existingCount: Int, newlyCreatedCount: Int) {
        self.processedCount = processedCount
        self.existingCount = existingCount
        self.newlyCreatedCount = newlyCreatedCount
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.processedCount = try container.decode(Int.self, forKey: .processedCount)
        self.existingCount = try container.decode(Int.self, forKey: .existingCount)
        self.newlyCreatedCount = try container.decode(Int.self, forKey: .newlyCreatedCount)
        super.init()
    }
    
    enum CodingKeys: String, CodingKey {
        case processedCount, existingCount, newlyCreatedCount
    }
}

/// Represents the result for an individual item in a batch detokenization operation.
@objc public class BatchDetokenItem: NSObject, Codable {
    @objc public let token: String
    @objc public let value: String?
    @objc public let exists: Bool
    @objc public let dataType: String?

    init(token: String, value: String?, exists: Bool, dataType: String?) {
        self.token = token
        self.value = value
        self.exists = exists
        self.dataType = dataType
        super.init()
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.token = try container.decode(String.self, forKey: .token)
        self.value = try container.decodeIfPresent(String.self, forKey: .value)
        self.exists = try container.decode(Bool.self, forKey: .exists)
        self.dataType = try container.decodeIfPresent(String.self, forKey: .dataType)
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case token, value, exists, dataType
    }
}

/// Summary statistics for a batch detokenization operation.
@objc public class BatchDetokenizeSummary: NSObject, Codable {
    @objc public let processedCount: Int
    @objc public let foundCount: Int
    @objc public let notFoundCount: Int

    @objc public init(processedCount: Int, foundCount: Int, notFoundCount: Int) {
        self.processedCount = processedCount
        self.foundCount = foundCount
        self.notFoundCount = notFoundCount
        super.init()
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.processedCount = try container.decode(Int.self, forKey: .processedCount)
        self.foundCount = try container.decode(Int.self, forKey: .foundCount)
        self.notFoundCount = try container.decode(Int.self, forKey: .notFoundCount)
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case processedCount, foundCount, notFoundCount
    }
}

/// Encrypted request model
struct EncryptedRequest: Codable {
    let itp: String
    let itk: String
    let itv: String
}

/// Encrypted response model
struct EncryptedResponse: Codable {
    let itp: String
    let itv: String
}
