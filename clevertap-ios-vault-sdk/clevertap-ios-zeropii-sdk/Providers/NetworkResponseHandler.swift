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
    
    func handleResponse<T: Codable>(
        data: Data,
        response: URLResponse,
        responseType: T.Type
    ) -> Result<T, ZeroPiiError> {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response", file: #file, line: #line)
            return .failure(.networkError)
        }
        
        logger.debug("Response status: \(httpResponse.statusCode), data size: \(data.count) bytes", file: #file, line: #line)
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(responseType, from: data)
                
                logger.debug("Successfully decoded response of type \(responseType)", file: #file, line: #line)
                return .success(decodedResponse)
            } catch {
                logger.error("Failed to decode response: \(error.localizedDescription)", file: #file, line: #line)
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("Response data: \(responseString.prefix(500))", file: #file, line: #line)
                }
                return .failure(.jsonParsingError)
            }
        case 400:
            logger.error("400 Bad Request", file: #file, line: #line)
            return .failure(.badRequest)

        case 401:
            logger.error("401 Unauthorized - token may be expired", file: #file, line: #line)
            return .failure(.unauthorized)

        case 403:
            logger.error("403 Forbidden", file: #file, line: #line)
            return .failure(.forbidden)

        case 404:
            logger.error("404 Not Found", file: #file, line: #line)
            return .failure(.notFound)

        case 405:
            logger.error("405 Method Not Allowed", file: #file, line: #line)
            return .failure(.methodNotAllowed)

        case 419:
            logger.warning("419 Backend decryption failure, falling back to non-encrypted requests", file: #file, line: #line)
            return .failure(.decryptionFailed)

        case 429:
            logger.warning("Server error \(httpResponse.statusCode) - rate limit exceeded", file: #file, line: #line)
            return .failure(.rateLimitExceeded)

        case 500, 502, 503, 504:
            logger.error("Server error \(httpResponse.statusCode)", file: #file, line: #line)
            return .failure(.serverError)

        default:
            logger.error("Unexpected status code \(httpResponse.statusCode)", file: #file, line: #line)
            return .failure(.serverError)
        }
    }
}
