//
//  CacheProvider.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 05/06/25.
//

import Foundation

/// Protocol defining a cache for token and value mappings.
protocol CacheProvider {

    /// Retrieves the token associated with a given value.
    ///
    /// - Parameter value: The value to look up.
    /// - Returns: The corresponding token, or `nil` if not found.
    func getToken(for value: String) -> (token: String, dataType: String)?

    /// Retrieves the value associated with a given token.
    ///
    /// - Parameter token: The token to look up.
    /// - Returns: The corresponding value, or `nil` if not found.
    func getValue(for token: String) -> (value: String, dataType: String)?

    /// Stores a token-to-value mapping.
    ///
    /// - Parameters:
    ///   - token: The token.
    ///   - value: The corresponding value.
    func putValue(token: String, value: String, dataType: String?)

    /// Stores a value-to-token mapping.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - token: The corresponding token.
    func putToken(value: String, token: String, dataType: String?)
    
    /// Checks if caching is enabled.
    func isEnabled() -> Bool
    
    /// Returns the number of entries in the token-to-value map.
    func size() -> Int

    /// Clears all cache entries.
    func clear()
}

