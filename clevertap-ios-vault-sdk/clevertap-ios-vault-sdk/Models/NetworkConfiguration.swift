//
//  NetworkConfiguration.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

/// Network configuration structure
/// Contains all settings needed to configure network operations for the Vault SDK
public struct NetworkConfiguration {
    
    // MARK: - Core Network Settings
    
    /// Base URL for tokenization API endpoints
    public let tokenizationBaseURL: String
    
    /// Base URL for authentication endpoints
    public let authBaseURL: String
    
    // MARK: - HTTP Configuration
    
    /// Custom HTTP headers to include with all requests
    /// Example: ["X-API-Version": "v2", "X-Client-Platform": "iOS"]
    public let customHeaders: [String: String]
    
    // MARK: - Initialization
    
    /// Complete initializer with all configuration options
    public init(tokenizationBaseURL: String,
                authBaseURL: String,
                customHeaders: [String: String] = [:]) {
        
        self.tokenizationBaseURL = tokenizationBaseURL
        self.authBaseURL = authBaseURL
        self.customHeaders = customHeaders
    }
    
    /// Simple initializer with just required parameters
    public init(tokenizationURL: String, authURL: String) {
        self.init(
            tokenizationBaseURL: tokenizationURL,
            authBaseURL: authURL
        )
    }
}
