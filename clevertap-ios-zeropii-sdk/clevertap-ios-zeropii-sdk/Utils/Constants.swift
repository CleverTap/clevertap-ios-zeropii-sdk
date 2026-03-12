//
//  Constants.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

struct Constants {
    static let tokenizeEndpoint: String = "/ct-vault/api/v2/tokenize"
    static let batchTokenizeEndpoint: String = "/ct-vault/api/v2/tokenize/batch"
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
