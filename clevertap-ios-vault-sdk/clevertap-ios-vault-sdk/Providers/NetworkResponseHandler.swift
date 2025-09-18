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
          // TODO
//        case 400:
//            logger.error("Bad request for authentication", file: #file, function: #function, line: #line)
//            return .failure(.badRequest)
//            
//        case 401:
//            logger.error("Authentication failed - invalid credentials", file: #file, function: #function, line: #line)
//            return .failure(.authenticationFailed)
//            
//        case 429:
//            logger.warning("Rate limit exceeded during authentication", file: #file, function: #function, line: #line)
//            return .failure(.rateLimitExceeded)
//            
//        case 500...599:
//            logger.error("Server error during authentication: \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
//            return .failure(.serverError)
            
        default:
            logger.error("Unexpected status code during authentication: \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
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
          // TODO
//        case 400:
//            logger.error("Bad request", file: #file, function: #function, line: #line)
//            return .failure(.badRequest)
//            
//        case 401:
//            logger.warning("Unauthorized - token may be expired", file: #file, function: #function, line: #line)
//            return .failure(.unauthorized)
//            
//        case 403:
//            logger.error("Forbidden", file: #file, function: #function, line: #line)
//            return .failure(.forbidden)
//            
//        case 404:
//            logger.error("Not found", file: #file, function: #function, line: #line)
//            return .failure(.notFound)
//            
//        case 405:
//            logger.error("Method not allowed", file: #file, function: #function, line: #line)
//            return .failure(.methodNotAllowed)
//            
//        case 429:
//            logger.warning("Rate limit exceeded", file: #file, function: #function, line: #line)
//            return .failure(.rateLimitExceeded)
//            
//        case 500...599:
//            let errorCode = VaultError.fromHTTPStatusCode(httpResponse.statusCode)
//            logger.error("Server error: \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
//            return .failure(errorCode)
            
        default:
            logger.error("Unexpected status code: \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            return .failure(.serverError)
        }
    }
}
