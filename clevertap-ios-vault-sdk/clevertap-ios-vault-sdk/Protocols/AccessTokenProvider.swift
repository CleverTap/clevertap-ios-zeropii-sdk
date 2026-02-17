//
//  AccessTokenProvider.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 17/02/26.
//

import Foundation

/// Provider protocol for supplying access tokens to the Vault SDK.
///
/// Implement this protocol to supply authentication tokens from your
/// application's auth system. The SDK calls ``fetchToken(completion:)`` when it needs
/// a new or refreshed token.
///
/// **Contract:** Implementors MUST call exactly one of
/// `completion(.success(tokenInfo))` or `completion(.failure(error))`.
/// Never call both, and never call neither (SDK will hang indefinitely).
@objc public protocol AccessTokenProvider {
    /// Called by the SDK when it needs a new or refreshed access token.
    ///
    /// - Parameter completion: A callback that MUST be invoked with either
    ///   a valid ``AccessTokenInfo`` on success, or an `Error` on failure.
    func fetchToken(completion: @escaping (AccessTokenInfo?, Error?) -> Void)
}

/// Holds the access token and its expiry information returned by the app's token provider.
@objc public class AccessTokenInfo: NSObject {
    /// The bearer access token string.
    @objc public let token: String

    /// The number of seconds until this token expires (from now).
    @objc public let expiresInSeconds: Int

    /// Creates a new ``AccessTokenInfo``.
    ///
    /// - Parameters:
    ///   - token: The bearer access token string.
    ///   - expiresInSeconds: The number of seconds until the token expires.
    @objc public init(token: String, expiresInSeconds: Int) {
        self.token = token
        self.expiresInSeconds = expiresInSeconds
        super.init()
    }
}
