//
//  NetworkResponseHandler.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

class NetworkResponseHandler {
    private let logger: VaultLoggerProtocol
    
    init(logger: VaultLoggerProtocol) {
        self.logger = logger
    }
    
    func handleAuthResponse(data: Data, response: URLResponse) -> Result<AuthTokenResponse, VaultError> {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for auth request", file: #file, function: #function, line: #line)
            return .failure(.networkError)
        }
        
        logger.debug("Auth response status: \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let authResponse = try decoder.decode(AuthTokenResponse.self, from: data)
                
                logger.debug("Successfully decoded auth response", file: #file, function: #function, line: #line)
                return .success(authResponse)
            } catch {
                logger.error("Failed to decode auth response: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("Response data: \(responseString)", file: #file, function: #function, line: #line)
                }
                return .failure(.jsonParsingError)
            }
        case 400:
            logger.error("400 Bad Request", file: #file, function: #function, line: #line)
            return .failure(.badRequest)

        case 401:
            logger.error("401 Unauthorized - authentication failed", file: #file, function: #function, line: #line)
            return .failure(.authenticationFailed)

        case 429:
            logger.warning("Server error \(httpResponse.statusCode) - rate limit exceeded", file: #file, function: #function, line: #line)
            return .failure(.rateLimitExceeded)

        case 500, 502, 503, 504:
            logger.error("Server error \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            return .failure(.serverError)

        default:
            logger.error("Unexpected status code \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            return .failure(.serverError)
        }
    }
    
    func handleResponse<T: Codable>(
        data: Data,
        response: URLResponse,
        responseType: T.Type
    ) -> Result<T, VaultError> {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response", file: #file, function: #function, line: #line)
            return .failure(.networkError)
        }
        
        logger.debug("Response status: \(httpResponse.statusCode), data size: \(data.count) bytes", file: #file, function: #function, line: #line)
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(responseType, from: data)
                
                logger.debug("Successfully decoded response of type \(responseType)", file: #file, function: #function, line: #line)
                return .success(decodedResponse)
            } catch {
                logger.error("Failed to decode response: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("Response data: \(responseString.prefix(500))", file: #file, function: #function, line: #line)
                }
                return .failure(.jsonParsingError)
            }
        case 400:
            logger.error("400 Bad Request", file: #file, function: #function, line: #line)
            return .failure(.badRequest)

        case 401:
            logger.error("401 Unauthorized - token may be expired", file: #file, function: #function, line: #line)
            return .failure(.unauthorized)

        case 403:
            logger.error("403 Forbidden", file: #file, function: #function, line: #line)
            return .failure(.forbidden)

        case 404:
            logger.error("404 Not Found", file: #file, function: #function, line: #line)
            return .failure(.notFound)

        case 405:
            logger.error("405 Method Not Allowed", file: #file, function: #function, line: #line)
            return .failure(.methodNotAllowed)

        case 429:
            logger.warning("Server error \(httpResponse.statusCode) - rate limit exceeded", file: #file, function: #function, line: #line)
            return .failure(.rateLimitExceeded)

        case 500, 502, 503, 504:
            logger.error("Server error \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            return .failure(.serverError)

        default:
            logger.error("Unexpected status code \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            return .failure(.serverError)
        }
    }
}
