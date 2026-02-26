//
//  TokenModels.swift
//  clevertap-ios-zeropii-sdk
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

/// Request model for batch tokenization.
struct BatchTokenizeRequest: Codable {
    let values: [String]
}

/// Response model for batch tokenization.
struct BatchTokenizeResponse: Codable {
    let results: [BatchTokenItem]
    let summary: BatchTokenizeSummary
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
