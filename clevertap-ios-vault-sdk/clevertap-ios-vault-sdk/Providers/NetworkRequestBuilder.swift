//
//  NetworkRequestBuilder.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

class NetworkRequestBuilder {
    private var configuration: NetworkConfiguration
    private let logger: VaultLoggerProtocol
    
    init(configuration: NetworkConfiguration, logger: VaultLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
    }
    
    func updateConfiguration(_ configuration: NetworkConfiguration) {
        self.configuration = configuration
    }
    
    func buildAuthRequest(clientId: String, clientSecret: String) throws -> URLRequest {
        guard let url = URL(string: configuration.authBaseURL + Constants.oauthTokenEndpoint) else {
            logger.debug("Invalid auth URL: \(configuration.authBaseURL)", file: #file, function: #function, line: #line)
            throw VaultError.invalidBaseURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in configuration.customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let bodyString = "grant_type=\(Constants.oauthGrantType)&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)
        
        logger.debug("Built auth request for URL: \(url.absoluteString)", file: #file, function: #function, line: #line)
        
        return request
    }
    
    func buildRequest<T: Codable>(
        endpoint: String,
        body: T,
        accessToken: String
    ) throws -> URLRequest {
        
        guard let url = URL(string: configuration.tokenizationBaseURL + endpoint) else {
            logger.error("Invalid tokenization URL: \(configuration.tokenizationBaseURL + endpoint)", file: #file, function: #function, line: #line)
            throw VaultError.invalidBaseURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Encrypted")
        
        for (key, value) in configuration.customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData
            
            logger.debug("Built request for URL: \(url.absoluteString), body size: \(bodyData.count) bytes", file: #file, function: #function, line: #line)
            
        } catch {
            logger.error("Failed to encode request body: \(error.localizedDescription)", file: #file, function: #function, line: #line)
            throw VaultError.jsonParsingError
        }
        
        return request
    }
}

