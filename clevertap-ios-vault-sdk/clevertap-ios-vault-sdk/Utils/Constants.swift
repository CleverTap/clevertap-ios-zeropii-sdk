//
//  Constants.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

struct Constants {
    static let oauthTokenEndpoint: String = "protocol/openid-connect/token" // TODO
    static let oauthGrantType: String = "client_credentials"
    static let tokenizeEndpoint: String = "api/tokenization/getToken" // TODO
    static let detokenizeEndpoint: String = "" // TODO
    static let batchTokenizeEndpoint: String = "" // TODO
    static let batchDetokenizeEndpoint: String = "" // TODO
}

/// String or number value
enum StringOrInt: Codable {
    case string(String)
    case int(Int)

    var stringValue: String {
        switch self {
        case .string(let str): return str
        case .int(let num):    return "\(num)"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else {
            let context = DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or Number"
            )
            throw DecodingError.typeMismatch(StringOrInt.self, context)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):   try container.encode(str)
        case .int(let val):      try container.encode(val)
        }
    }
}
