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
    private let maxBatchSizeTokenize: Int = 1000
    private let maxBatchSizeDetokenize: Int = 10000
    
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
    
    
    public func detokenize(_ token: String) async -> DetokenizeResult {
        guard !token.isEmpty else {
            logger.warning("Empty token provided for detokenization", file: #file, function: #function, line: #line)
            return .error(message: "Empty token passed")
        }
        
        // Check cache first if enabled
        if cacheProvider.isEnabled() {
            if let cachedValue = cacheProvider.getValue(for: token) {
                logger.debug("Value found in cache", file: #file, function: #function, line: #line)
                return .success(value: cachedValue, exists: true, dataType: "string")
            }
        }
        
        // Perform detokenization with retry logic
        let result = await performWithRetry(operation: "detokenize", maxAttempts: 3) {
            await self.performDetokenization(token: token)
        }
        
        switch result {
        case .success(let response):
            return .success(value: response.value, exists: response.exists, dataType: response.dataType)
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
    }
    
    public func batchTokenize(_ values: [String]) async -> BatchTokenizeResult {
        guard !values.isEmpty else {
            logger.warning("Batch tokenize request contains no values", file: #file, function: #function, line: #line)
            return .error(message: "Empty values passed")
        }
        
        guard values.count <= maxBatchSizeTokenize else {
            logger.error("Batch size \(values.count) exceeds maximum \(maxBatchSizeTokenize)", file: #file, function: #function, line: #line)
            return .error(message: "Batch size exceeds maximum limit")
        }
        
        var (cachedResults, uncachedValues) = separateCachedValues(values)
        logger.debug("Batch tokenize: \(cachedResults.count) cached, \(uncachedValues.count) uncached", file: #file, function: #function, line: #line)
        
        // If all values are cached, return immediately
        if uncachedValues.isEmpty {
            logger.debug("All tokens found in cache", file: #file, function: #function, line: #line)
            return .success(results: cachedResults, summary: BatchTokenizeSummary(processedCount: values.count, existingCount: values.count, newlyCreatedCount: 0))
        }
        
        // Process uncached values
        let result = await performWithRetry(operation: "batchTokenize", maxAttempts: 3) {
            await self.performBatchTokenization(values: uncachedValues)
        }
        
        switch result {
        case .success(let response):
            cachedResults.append(contentsOf: response.results)
            return .success(results: cachedResults,
                            summary: BatchTokenizeSummary(processedCount: cachedResults.count,
                                                          existingCount: cachedResults.count { $0.exists },
                                                          newlyCreatedCount: cachedResults.count { $0.newlyCreated }))
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
    }
    
    public func batchDetokenize(_ tokens: [String]) async -> BatchDetokenizeResult {
        guard !tokens.isEmpty else {
            logger.warning("Batch detokenize request contains no tokens", file: #file, function: #function, line: #line)
            return .error(message: "Empty tokens passed")
        }
        
        guard tokens.count <= maxBatchSizeDetokenize else {
            logger.error("Batch size \(tokens.count) exceeds maximum \(maxBatchSizeDetokenize)", file: #file, function: #function, line: #line)
            return .error(message: "Batch size exceeds maximum limit")
        }
        
        var (cachedResults, uncachedTokens) = separateCachedTokens(tokens)
        logger.debug("Batch detokenize: \(cachedResults.count) cached, \(uncachedTokens.count) uncached", file: #file, function: #function, line: #line)
        
        // If all tokens are cached, return immediately
        if uncachedTokens.isEmpty {
            logger.debug("All values found in cache", file: #file, function: #function, line: #line)
            return .success(results: cachedResults, summary: BatchDetokenizeSummary(processedCount: cachedResults.count, foundCount: cachedResults.count, notFoundCount: 0))
        }
        
        // Process uncached tokens
        let result = await performWithRetry(operation: "batchDetokenize", maxAttempts: 3) {
            await self.performBatchDetokenization(tokens: uncachedTokens)
        }

        switch result {
        case .success(let response):
            cachedResults.append(contentsOf: response.results)
            return .success(results: cachedResults,
                            summary: BatchDetokenizeSummary(processedCount: cachedResults.count,
                                                            foundCount: cachedResults.count { $0.exists },
                                                            notFoundCount: cachedResults.count { !$0.exists }))
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
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
    
    private func performDetokenization(token: String) async -> Result<DetokenizeResponse, VaultError> {
        do {
            let tokenResult = try await authRepository.getAccessToken()
            guard case .success(let accessToken) = tokenResult else {
                logger.error("Failed to get access token for detokenization", file: #file, function: #function, line: #line)
                return .failure(.authenticationFailed)
            }
            
            let request = DetokenizeRequest(token: token)
            do {
                let networkResult = try await networkProvider.detokenize(request, accessToken: accessToken)
                
                switch networkResult {
                case .success(let response):
                    guard let value = response.value else {
                        return .failure(.invalidDetokenisationResponse)
                    }
                    
                    // Cache the result if caching is enabled
                    if cacheProvider.isEnabled() {
                        cacheProvider.putValue(token: token, value: value)
                    }
                    
                    logger.debug("Detokenization successful", file: #file, function: #function, line: #line)
                    return .success(response)
                    
                case .failure(_):
                    logger.error("Detokenization failed", file: #file, function: #function, line: #line)
                    return .failure(.invalidDetokenisationResponse)
                }
            } catch {
                return .failure(.detokenisationFalied)
            }
        } catch {
            return.failure(.authenticationFailed)
        }
    }
    
    private func performBatchTokenization(values: [String]) async -> Result<BatchTokenizeResponse, VaultError> {
        do {
            let tokenResult = try await authRepository.getAccessToken()
            guard case .success(let accessToken) = tokenResult else {
                logger.error("Failed to get access token for batch tokenization", file: #file, function: #function, line: #line)
                return .failure(.authenticationFailed)
            }
            
            let request = BatchTokenizeRequest(values: values)
            do {
                let networkResult = try await networkProvider.batchTokenize(request, accessToken: accessToken)
                
                switch networkResult {
                case .success(let response):
                    // Cache the result if caching is enabled
                    if cacheProvider.isEnabled() {
                        for item in response.results {
                            if item.exists || item.newlyCreated {
                                cacheProvider.putToken(value: item.originalValue, token: item.token)
                                cacheProvider.putValue(token: item.token, value: item.originalValue)
                            }
                        }
                    }
                    
                    logger.debug("Batch Tokenization successful", file: #file, function: #function, line: #line)
                    return .success(response)
                    
                case .failure(_):
                    logger.error("Batch Tokenization failed", file: #file, function: #function, line: #line)
                    return .failure(.invalidBatchTokenisationResponse)
                }
            } catch {
                return .failure(.batchTokenisationFalied)
            }
        } catch {
            return.failure(.authenticationFailed)
        }
    }
    
    private func performBatchDetokenization(tokens: [String]) async -> Result<BatchDetokenizeResponse, VaultError> {
        do {
            let tokenResult = try await authRepository.getAccessToken()
            guard case .success(let accessToken) = tokenResult else {
                logger.error("Failed to get access token for batch detokenization", file: #file, function: #function, line: #line)
                return .failure(.authenticationFailed)
            }
            
            
            let request = BatchDetokenizeRequest(tokens: tokens)
            do {
                let networkResult = try await networkProvider.batchDetokenize(request, accessToken: accessToken)
                
                switch networkResult {
                case .success(let response):
                    // Cache the result if caching is enabled
                    if cacheProvider.isEnabled() {
                        for item in response.results {
                            if let value = item.value, item.exists {
                                cacheProvider.putValue(token: item.token, value: value)
                            }
                        }
                    }
                    
                    logger.debug("Batch Detokenization successful", file: #file, function: #function, line: #line)
                    return .success(response)
                    
                case .failure(_):
                    logger.error("Batch Detokenization failed", file: #file, function: #function, line: #line)
                    return .failure(.invalidBatchDetokenisationResponse)
                }
            } catch {
                return .failure(.batchDetokenisationFalied)
            }
        } catch {
            return.failure(.authenticationFailed)
        }
    }
    
    private func separateCachedValues(_ values: [String]) -> ([BatchTokenItem], [String]) {
        if !cacheProvider.isEnabled() {
            return ([], values)
        }
        
        var cachedResults: [BatchTokenItem] = []
        var uncachedValues: [String] = []
        
        for (_, value) in values.enumerated() {
            if let cachedToken = cacheProvider.getToken(for: value) {
                cachedResults.append(BatchTokenItem(originalValue: value, token: cachedToken, exists: true, newlyCreated: false, dataType: "string"))
            } else {
                uncachedValues.append(value)
            }
        }
        
        return (cachedResults, uncachedValues)
    }
    
    private func separateCachedTokens(_ tokens: [String]) -> ([BatchDetokenItem], [String]) {
        if !cacheProvider.isEnabled() {
            return ([], tokens)
        }
        
        var cachedResults: [BatchDetokenItem] = []
        var uncachedTokens: [String] = []
        
        for (_, token) in tokens.enumerated() {
            if let cachedValue = cacheProvider.getValue(for: token) {
                cachedResults.append(BatchDetokenItem(token: token, value: cachedValue, exists: true, dataType: "string"))
            } else {
                uncachedTokens.append(token)
            }
        }
        
        return (cachedResults, uncachedTokens)
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
