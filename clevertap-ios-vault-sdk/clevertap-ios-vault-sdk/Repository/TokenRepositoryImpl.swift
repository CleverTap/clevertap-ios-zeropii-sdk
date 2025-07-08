//
//  TokenRepositoryImpl.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

actor TokenRepositoryImpl: TokenRepository {
    
    // MARK: - Dependencies
    private let networkProvider: NetworkProvider
    private let authRepository: AuthRepository
    private let cacheProvider: CacheProvider
    private let logger: VaultLogger
    private let initialRetryDelayMs: Int = 1000
    
    // MARK: - Initialization
    init(networkProvider: NetworkProvider,
        authRepository: AuthRepository,
        cacheProvider: CacheProvider,
        logger: VaultLogger = VaultLogger.shared) {
        
        self.networkProvider = networkProvider
        self.authRepository = authRepository
        self.cacheProvider = cacheProvider
        self.logger = logger
        
        logger.debug("TokenRepository initialized", file: #file, function: #function, line: #line)
    }
    
    // MARK: - TokenRepository Protocol Implementation
    
    public func tokenize(_ value: String) async -> TokenizeResult {
        guard !value.isEmpty else {
            logger.warning("Empty value provided for tokenization", file: #file, function: #function, line: #line)
            return .error(message: "Empty value passed")
        }
        
        // Check cache first if enabled
        if cacheProvider.isEnabled() {
            if let cachedToken = cacheProvider.getToken(for: value) {
                logger.debug("Token found in cache", file: #file, function: #function, line: #line)
                return .success(token: cachedToken, exists: true, newlyCreated: false, dataType: "string")
            }
        }
        
        // Perform tokenization with retry logic
        let result = await performWithRetry(operation: "tokenize", maxAttempts: 3) {
            await self.performTokenization(value: value)
        }
        
        switch result {
        case .success(let response):
            return .success(token: response.token, exists: response.exists, newlyCreated: response.newlyCreated, dataType: response.dataType)
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
    }
    
    
    func detokenize(_ token: String) async -> DetokenizeResult {
        // TODO
        return .error(message: "TODO")
    }
    
    func batchTokenize(_ values: [String]) async -> BatchTokenizeResult {
        // TODO
        return .error(message: "TODO")
    }
    
    func batchDetokenize(_ tokens: [String]) async -> BatchDetokenizeResult {
        // TODO
        return .error(message: "TODO")
    }
    
    // MARK: - Private Implementation Methods
    
    private func performTokenization(value: String) async -> Result<TokenizeResponse, VaultError> {
        do {
            let tokenResult = try await authRepository.getAccessToken()
            guard case .success(let accessToken) = tokenResult else {
                logger.error("Failed to get access token for tokenization", file: #file, function: #function, line: #line)
                return .failure(.authenticationFailed)
            }
            
            let request = TokenizeRequest(value: value)
            do {
                let networkResult = try await networkProvider.tokenize(request, accessToken: accessToken)
                
                switch networkResult {
                case .success(let response):
                    // Cache the result if caching is enabled
                    if cacheProvider.isEnabled() {
                        cacheProvider.putToken(value: value, token: response.token)
                    }
                    
                    logger.debug("Tokenization successful", file: #file, function: #function, line: #line)
                    return .success(response)
                    
                case .failure(_):
                    logger.error("Tokenisation failed", file: #file, function: #function, line: #line)
                    return .failure(.invalidTokenisationResponse)
                }
            } catch {
                return .failure(.tokenisationFalied)
            }
        } catch {
            return.failure(.authenticationFailed)
        }
    }
    
    
    
    // MARK: - Retry Logic
    
    private func performWithRetry<T>(
        operation: String,
        maxAttempts: Int,
        block: () async -> Result<T, VaultError>
    ) async -> Result<T, VaultError> {
        var lastError: VaultError = .networkError
        
        for attempt in 0..<maxAttempts {
            let result = await block()
            
            switch result {
            case .success:
                if attempt > 0 {
                    logger.info("Operation \(operation) succeeded after \(attempt + 1) attempts", file: #file, function: #function, line: #line)
                }
                return result
                
            case .failure(let error):
                lastError = error
                if attempt == maxAttempts - 1 {
                    logger.error("Operation \(operation) failed after \(attempt + 1) attempts: \(error.localizedDescription)", file: #file, function: #function, line: #line)
                    break
                }
                
                // Handle token refresh for 401 errors
                if error == .unauthorized {
                    logger.debug("Attempting token refresh for unauthorized 401 error", file: #file, function: #function, line: #line)
                    do {
                        let refreshResult = try await authRepository.refreshAccessToken()
                        if case .failure(let refreshError) = refreshResult {
                            logger.error("Token refresh failed: \(refreshError.localizedDescription)", file: #file, function: #function, line: #line)
                            return .failure(refreshError)
                        }
                    } catch {
                        return .failure(.refreshTokenError)
                    }
                }
                
                let delayMs = initialRetryDelayMs * (1 << attempt)
                logger.debug("Retrying operation \(operation) in \(delayMs)s (attempt \(attempt + 1)/\(maxAttempts))", file: #file, function: #function, line: #line)
                
                try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            }
        }
        
        return .failure(lastError)
    }
}
