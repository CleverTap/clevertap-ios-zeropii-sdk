//
//  AuthRepositoryImpl.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

/// Implementation of ``AuthRepository`` that delegates token acquisition
/// to an app-provided ``AccessTokenProvider``.
///
/// This class handles:
/// - Caching valid tokens to avoid unnecessary provider calls
/// - Refreshing expired tokens automatically (with a 30-second safety buffer)
/// - Bridging the callback-based ``AccessTokenProvider`` to async/await
class AuthRepositoryImpl: AuthRepository {

    private let tokenProvider: AccessTokenProvider
    private let logger: VaultLogger

    private var currentAccessToken: String?
    private var tokenExpiryDate: Date?

    init(tokenProvider: AccessTokenProvider,
         logger: VaultLogger = VaultLogger.shared) {
        self.tokenProvider = tokenProvider
        self.logger = logger
    }

    func getAccessToken() async -> Result<String, VaultError> {
        if isTokenValid(), let token = currentAccessToken {
            logger.info("Using existing auth token", file: #file, function: #function, line: #line)
            return .success(token)
        }

        logger.info("Requesting new auth token", file: #file, function: #function, line: #line)
        return await refreshAccessToken()
    }

    func refreshAccessToken() async -> Result<String, VaultError> {
        return await fetchTokenFromProvider()
    }

    func isTokenValid() -> Bool {
        guard let _ = currentAccessToken,
              let expiryDate = tokenExpiryDate else {
            return false
        }

        let bufferTime: TimeInterval = 30 // 30 second safety buffer
        return Date().addingTimeInterval(bufferTime) < expiryDate
    }

    // MARK: - Private Methods

    private func fetchTokenFromProvider() async -> Result<String, VaultError> {
        return await withCheckedContinuation { continuation in
            tokenProvider.fetchToken { [weak self] tokenInfo, error in
                guard let self = self else {
                    continuation.resume(returning: .failure(.authenticationFailed))
                    return
                }

                if let error = error {
                    self.logger.error("Token provider returned error: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                    continuation.resume(returning: .failure(.authenticationFailed))
                    return
                }

                guard let tokenInfo = tokenInfo else {
                    self.logger.error("Token provider returned nil token info", file: #file, function: #function, line: #line)
                    continuation.resume(returning: .failure(.authenticationFailed))
                    return
                }

                self.currentAccessToken = tokenInfo.token
                self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenInfo.expiresInSeconds))
                self.logger.debug("Auth token refreshed, expires in \(tokenInfo.expiresInSeconds) seconds", file: #file, function: #function, line: #line)

                continuation.resume(returning: .success(tokenInfo.token))
            }
        }
    }
}
