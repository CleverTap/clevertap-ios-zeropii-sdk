//
//  AuthRepositoryImpl.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

class AuthRepositoryImpl: AuthRepository {
    
    private let networkProvider: NetworkProvider
    private let keychainManager: KeychainManager = KeychainManager()
    private let logger: VaultLogger
    private let clientId: String
    private let clientSecret: String
    
    private var currentAccessToken: String?
    private var tokenExpiryDate: Date?
    
    private let accessTokenKey = "vault_access_token"
    private let tokenExpiryKey = "vault_token_expiry"
    
    init(networkProvider: NetworkProvider,
         clientId: String,
         clientSecret: String,
         logger: VaultLogger = VaultLogger.shared) {
        self.networkProvider = networkProvider
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.logger = logger
        
        loadTokenFromKeychain()
    }
    
    func getAccessToken() async -> Result<String, VaultError> {
        if isTokenValid(), let token = currentAccessToken {
            logger.info("Using existing auth token", file: #file, function: #function, line: #line)
            return .success(token)
        }
        
        logger.info("Requesting new auth token", file: #file, function: #function, line: #line)
        return await requestNewAccessToken()
    }
    
    func refreshAccessToken() async -> Result<String, VaultError> {
        return await requestNewAccessToken()
    }
    
    func isTokenValid() -> Bool {
        guard let _ = currentAccessToken,
              let expiryDate = tokenExpiryDate else {
            return false
        }

        let bufferTime: TimeInterval = 30 // 30 second
        return Date().addingTimeInterval(bufferTime) < expiryDate
    }
    
    // MARK: - Private Methods

    private func requestNewAccessToken() async -> Result<String, VaultError> {
        do {
            let result = try await networkProvider.getAccessToken(
                clientId: clientId,
                clientSecret: clientSecret
            )

            switch result {
            case .success(let response):
                logger.debug("Auth token refreshed, expires in \(response.expiresIn) seconds", file: #file, function: #function, line: #line)
                self.currentAccessToken = response.accessToken
                self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(response.expiresIn))

                saveTokenToKeychain()
                return .success(response.accessToken)

            case .failure:
                return .failure(VaultError.authenticationFailed)
            }
        } catch {
            return .failure(VaultError.authenticationFailed)
        }
    }
    
    private func loadTokenFromKeychain() {
        if let tokenData = keychainManager.getData(forKey: accessTokenKey),
           let token = String(data: tokenData, encoding: .utf8) {
            self.currentAccessToken = token
        }
        
        if let expiryData = keychainManager.getData(forKey: tokenExpiryKey),
           let expiryString = String(data: expiryData, encoding: .utf8),
           let expiryTimestamp = Double(expiryString) {
            self.tokenExpiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        }
    }
    
    private func saveTokenToKeychain() {
        if let token = currentAccessToken {
            let tokenData = token.data(using: .utf8)!
            keychainManager.setData(tokenData, forKey: accessTokenKey)
        }
        
        if let expiryDate = tokenExpiryDate {
            let expiryString = String(expiryDate.timeIntervalSince1970)
            let expiryData = expiryString.data(using: .utf8)!
            keychainManager.setData(expiryData, forKey: tokenExpiryKey)
        }
    }
}
