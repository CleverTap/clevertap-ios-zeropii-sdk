//
//  AuthRepository.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol for managing authentication with the Vault API.
protocol AuthRepository {
    
    /// Gets a valid authentication token, refreshing it if necessary.
    ///
    /// - Returns: A valid access token as a `String`.
    ///
    /// - Note: This method may perform asynchronous network operations and should be called accordingly.
    func getAccessToken() async -> Result<String, VaultError>

    /// Requests a new access token from the token provider.
    ///
    /// - Returns: A newly issued access token as a `String`.
    ///
    /// - Note: This method delegates to the app-provided token provider.
    func refreshAccessToken() async -> Result<String, VaultError>
    
    /// Checks if the current token is valid.
    ///
    /// - Returns: `true` if the token is valid, otherwise `false`.
    func isTokenValid() -> Bool
}

