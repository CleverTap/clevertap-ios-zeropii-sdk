//
//  NetworkConfiguration.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 18/09/25.
//

import Foundation

/// Network configuration structure
/// Contains all settings needed to configure network operations for the ZeroPii SDK
public struct NetworkConfiguration {

    // MARK: - Core Network Settings

    /// Base URL for tokenization API endpoints
    public let tokenizationBaseURL: String

    // MARK: - Initialization

    public init(tokenizationBaseURL: String) {
        self.tokenizationBaseURL = tokenizationBaseURL
    }
}
