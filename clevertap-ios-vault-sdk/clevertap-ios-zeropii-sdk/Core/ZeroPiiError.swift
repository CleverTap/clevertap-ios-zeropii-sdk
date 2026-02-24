//
//  ZeroPiiError.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

enum ZeroPiiError: Int, Error {

    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case decryptionFailed = 419
    case rateLimitExceeded = 429
    case serverError = 500
    case authenticationFailed = 1000
    case tokenisationFalied = 1001
    case invalidTokenisationResponse = 1002
    case networkError = 1003
    case batchTokenisationFalied = 1007
    case invalidBatchTokenisationResponse = 1008
    case invalidBaseURL = 1011
    case jsonParsingError = 1012
    case buildRequestError = 1015

    // MARK: - Localized Error Description
    public var errorDescription: String? {
        switch self {
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized error."
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not found"
        case .methodNotAllowed:
            return "Method not allowed"
        case .decryptionFailed:
            return "Backend decryption failure."
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .authenticationFailed:
            return "Authentication failed error."
        case .tokenisationFalied:
            return "Tokenisation failed error."
        case .invalidTokenisationResponse:
            return "Invalid tokenization response type."
        case .networkError:
            return "Network error."
        case .batchTokenisationFalied:
            return "Batch tokenisation failed error."
        case .invalidBatchTokenisationResponse:
            return "Invalid batch tokenization response type."
        case .invalidBaseURL:
            return "Invalid Auth base URL"
        case .jsonParsingError:
            return "Failed to parse JSON"
        case .buildRequestError:
            return "Failed to build request"
        }
    }
}

/// Pairs a `ZeroPiiError` with the exact HTTP status code returned by the server.
/// `httpStatusCode` is the raw value from `HTTPURLResponse.statusCode` — it is `nil`
/// only for SDK-level errors (network failures, auth errors, build errors) that were
/// never received as an HTTP response.
struct ZeroPiiNetworkFailure: Error {
    let error: ZeroPiiError
    let httpStatusCode: Int?
}
