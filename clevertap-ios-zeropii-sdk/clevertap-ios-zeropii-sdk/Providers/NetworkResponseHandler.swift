//
//  NetworkResponseHandler.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

class NetworkResponseHandler {
    private let logger: ZeroPiiLoggerProtocol
    
    init(logger: ZeroPiiLoggerProtocol) {
        self.logger = logger
    }
    
    /// Returns the decoded response paired with the raw HTTP status code.
    /// The status code is `nil` only when the response is not an HTTP response at all.
    /// For every HTTP error case the exact status code from the server is preserved,
    /// giving callers full parity with Android's `response.code()` approach.
    func handleResponse<T: Codable>(
        data: Data,
        response: URLResponse,
        responseType: T.Type
    ) -> (result: Result<T, ZeroPiiError>, httpStatusCode: Int?) {

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response", file: #file, line: #line)
            return (.failure(.networkError), nil)
        }

        let statusCode = httpResponse.statusCode
        logger.debug("Response status: \(statusCode), data size: \(data.count) bytes", file: #file, line: #line)

        switch statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(responseType, from: data)
                logger.debug("Successfully decoded response of type \(responseType)", file: #file, line: #line)
                return (.success(decodedResponse), nil)
            } catch {
                logger.error("Failed to decode response: \(error.localizedDescription)", file: #file, line: #line)
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("Response data: \(responseString.prefix(500))", file: #file, line: #line)
                }
                return (.failure(.jsonParsingError), nil)
            }

        case 400:
            logger.error("400 Bad Request", file: #file, line: #line)
            return (.failure(.badRequest), statusCode)

        case 401:
            logger.error("401 Unauthorized - token may be expired", file: #file, line: #line)
            return (.failure(.unauthorized), statusCode)

        case 403:
            logger.error("403 Forbidden", file: #file, line: #line)
            return (.failure(.forbidden), statusCode)

        case 404:
            logger.error("404 Not Found", file: #file, line: #line)
            return (.failure(.notFound), statusCode)

        case 405:
            logger.error("405 Method Not Allowed", file: #file, line: #line)
            return (.failure(.methodNotAllowed), statusCode)

        case 419:
            logger.warning("419 Backend decryption failure, falling back to non-encrypted requests", file: #file, line: #line)
            return (.failure(.decryptionFailed), statusCode)

        case 429:
            logger.warning("\(statusCode) - rate limit exceeded", file: #file, line: #line)
            return (.failure(.rateLimitExceeded), statusCode)

        default:
            // Covers all 5xx codes (500, 502, 503, 504, …) and any unrecognised codes.
            // The exact statusCode is preserved so callers can report it precisely.
            logger.error("Server/unexpected error \(statusCode)", file: #file, line: #line)
            return (.failure(.serverError), statusCode)
        }
    }
}
