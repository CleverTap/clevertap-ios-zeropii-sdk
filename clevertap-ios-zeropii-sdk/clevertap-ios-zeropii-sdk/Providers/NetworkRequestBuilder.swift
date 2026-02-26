//
//  NetworkRequestBuilder.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

class NetworkRequestBuilder {
    private let configuration: NetworkConfiguration
    private let logger: ZeroPiiLoggerProtocol
    
    init(configuration: NetworkConfiguration, logger: ZeroPiiLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
    }

    func buildRequest<T: Codable>(
        endpoint: String,
        body: T,
        accessToken: String,
        encrypted: Bool = true
    ) throws -> URLRequest {

        guard let url = URL(string: configuration.tokenizationBaseURL + endpoint) else {
            logger.error("Invalid tokenization URL: \(configuration.tokenizationBaseURL + endpoint)", file: #file, line: #line)
            throw ZeroPiiError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if encrypted {
            request.setValue("true", forHTTPHeaderField: "Encrypted")
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData
            
            logger.debug("Built request for URL: \(url.absoluteString), body size: \(bodyData.count) bytes", file: #file, line: #line)
            
        } catch {
            logger.error("Failed to encode request body: \(error.localizedDescription)", file: #file, line: #line)
            throw ZeroPiiError.jsonParsingError
        }
        
        return request
    }
}

