//
//  TokenRepositoryImpl.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

actor TokenRepositoryImpl: TokenRepository {
    
    // MARK: - Dependencies
    private let networkProvider: NetworkProvider
    private let authRepository: AuthRepository
    private let cacheProvider: CacheProvider
    private let encryptionManager: EncryptionManager
    private let logger: ZeroPiiLogger
    private let initialRetryDelayMs: Int = 1000
    private let maxBatchSizeTokenize: Int = 1000
    private let maxBatchSizeDetokenize: Int = 10000

    // MARK: - Initialization
    init(networkProvider: NetworkProvider,
        authRepository: AuthRepository,
        cacheProvider: CacheProvider,
        encryptionManager: EncryptionManager,
        logger: ZeroPiiLogger = ZeroPiiLogger.shared) {
        
        self.networkProvider = networkProvider
        self.authRepository = authRepository
        self.cacheProvider = cacheProvider
        self.encryptionManager = encryptionManager
        self.logger = logger
        
        logger.debug("TokenRepository initialized", file: #file, line: #line)
    }
    
    // MARK: - TokenRepository Protocol Implementation
    
    public func tokenize(_ value: String) async -> TokenResult {
        guard !value.isEmpty else {
            logger.warning("Empty value provided for tokenization", file: #file, line: #line)
            return .error(message: "Empty value passed")
        }
        
        // Check cache first if enabled
        if cacheProvider.isEnabled() {
            if let tokenDetails = cacheProvider.getToken(for: value) {
                logger.debug("Token found in cache", file: #file, line: #line)
                return .success(token: tokenDetails.token, exists: true, newlyCreated: false, dataType: tokenDetails.dataType)
            }
        }
        
        // Perform tokenization with retry logic
        let result = await performWithRetry(operation: "tokenize", maxAttempts: 1) {
            await self.performTokenization(value: value)
        }
        
        switch result {
        case .success(let response):
            return .success(token: response.token.stringValue, exists: response.exists, newlyCreated: response.newlyCreated, dataType: response.dataType)
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
    }
    
    
    public func detokenize(_ token: String) async -> DetokenResult {
        guard !token.isEmpty else {
            logger.warning("Empty token provided for detokenization", file: #file, line: #line)
            return .error(message: "Empty token passed")
        }

        // Local-only lookup from cache (backed by encrypted preferences)
        if cacheProvider.isEnabled() {
            if let valueDetails = cacheProvider.getValue(for: token) {
                logger.debug("Value found in local store", file: #file, line: #line)
                return .success(value: valueDetails.value, exists: true, dataType: valueDetails.dataType)
            }
        }

        logger.debug("Token not found in local store", file: #file, line: #line)
        return .error(message: "Token not found in local store")
    }
    
    public func batchTokenize(_ values: [String]) async -> BatchTokenResult {
        guard !values.isEmpty else {
            logger.warning("Batch tokenize request contains no values", file: #file, line: #line)
            return .error(message: "Empty values passed")
        }
        
        guard values.count <= maxBatchSizeTokenize else {
            logger.error("Batch size \(values.count) exceeds maximum \(maxBatchSizeTokenize)", file: #file, line: #line)
            return .error(message: "Batch size exceeds maximum limit")
        }
        
        var (cachedResults, uncachedValues) = separateCachedValues(values)
        logger.debug("Batch tokenize: \(cachedResults.count) cached, \(uncachedValues.count) uncached", file: #file, line: #line)
        
        // If all values are cached, return immediately
        if uncachedValues.isEmpty {
            logger.debug("All tokens found in cache", file: #file, line: #line)
            return .success(results: cachedResults, summary: BatchTokenizeSummary(processedCount: values.count, existingCount: values.count, newlyCreatedCount: 0))
        }
        
        // Process uncached values
        let result = await performWithRetry(operation: "batchTokenize", maxAttempts: 1) {
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
    
    public func batchDetokenize(_ tokens: [String]) async -> BatchDetokenResult {
        guard !tokens.isEmpty else {
            logger.warning("Batch detokenize request contains no tokens", file: #file, line: #line)
            return .error(message: "Empty tokens passed")
        }

        guard tokens.count <= maxBatchSizeDetokenize else {
            logger.error("Batch size \(tokens.count) exceeds maximum \(maxBatchSizeDetokenize)", file: #file, line: #line)
            return .error(message: "Batch size exceeds maximum limit")
        }

        // Local-only lookup from cache (backed by encrypted preferences)
        var results = [BatchDetokenItem]()
        var foundCount = 0
        var notFoundCount = 0

        for token in tokens {
            if cacheProvider.isEnabled(), let valueDetails = cacheProvider.getValue(for: token) {
                results.append(BatchDetokenItem(token: token, value: valueDetails.value, exists: true, dataType: valueDetails.dataType))
                foundCount += 1
            } else {
                results.append(BatchDetokenItem(token: token, value: nil, exists: false, dataType: nil))
                notFoundCount += 1
            }
        }

        logger.debug("Batch detokenize local lookup: \(foundCount) found, \(notFoundCount) not found", file: #file, line: #line)
        return .success(results: results, summary: BatchDetokenizeSummary(processedCount: tokens.count, foundCount: foundCount, notFoundCount: notFoundCount))
    }
    
    // MARK: - Private Implementation Methods
    
    private func performTokenization(value: String) async -> Result<TokenizeResponse, ZeroPiiError> {
        let tokenResult = await authRepository.getAccessToken()
        guard case .success(let accessToken) = tokenResult else {
            logger.error("Failed to get access token for tokenization", file: #file, line: #line)
            return .failure(.authenticationFailed)
        }
        
        let request = TokenizeRequest(value: value)
        guard let encryptedRequest = encryptionManager.createEncryptedRequest(request) else {
            // TODO: Check for encrypted request failed case
            logger.error("Failed to get access token for tokenization", file: #file, line: #line)
            return .failure(.tokenisationFalied)
        }
        do {
            let networkResult = try await networkProvider.tokenize(encryptedRequest, accessToken: accessToken)
            
            switch networkResult {
            case .success(let response):
                let decryptedResult = encryptionManager.decrypt(encryptedPayload: response.itp, iv: response.itv)
                switch decryptedResult {
                case .success(let jsonData):
                    do {
                        let decodedObject = try JSONDecoder().decode(TokenizeResponse.self, from: jsonData)
                        // Cache the result if caching is enabled
                        if cacheProvider.isEnabled() {
                            cacheProvider.putToken(value: value, token: decodedObject.token.stringValue, dataType: decodedObject.dataType)
                            cacheProvider.putValue(token: decodedObject.token.stringValue, value: value, dataType: decodedObject.dataType)
                        }
                        
                        logger.debug("Tokenization successful", file: #file, line: #line)
                        return .success(decodedObject)
                    } catch (let error) {
                        logger.error("Failed to parse decrypted response: \(error.localizedDescription)", file: #file, line: #line)
                        return .failure(.tokenisationFalied)
                    }
                case .failure(message: let message):
                    logger.error("Failed to parse tokenization response: \(message)", file: #file, line: #line)
                    return .failure(.tokenisationFalied)
                }
            case .failure(_):
                logger.error("Tokenisation failed", file: #file, line: #line)
                return .failure(.invalidTokenisationResponse)
            }
        } catch {
            return .failure(.tokenisationFalied)
        }
    }
    
    private func performBatchTokenization(values: [String]) async -> Result<BatchTokenizeResponse, ZeroPiiError> {
        let tokenResult = await authRepository.getAccessToken()
        guard case .success(let accessToken) = tokenResult else {
            logger.error("Failed to get access token for batch tokenization", file: #file, line: #line)
            return .failure(.authenticationFailed)
        }
        
        let request = BatchTokenizeRequest(values: values)
        guard let encryptedRequest = encryptionManager.createEncryptedRequest(request) else {
            // TODO: Check for encrypted request failed case
            logger.error("Failed to get access token for tokenization", file: #file, line: #line)
            return .failure(.tokenisationFalied)
        }
        do {
            let networkResult = try await networkProvider.batchTokenize(encryptedRequest, accessToken: accessToken)
            
            switch networkResult {
            case .success(let response):
                let decryptedResult = encryptionManager.decrypt(encryptedPayload: response.itp, iv: response.itv)
                switch decryptedResult {
                case .success(let jsonData):
                    do {
                        let decodedObject = try JSONDecoder().decode(BatchTokenizeResponse.self, from: jsonData)
                        // Cache the result if caching is enabled
                        if cacheProvider.isEnabled() {
                            for item in decodedObject.results {
                                if item.exists || item.newlyCreated {
                                    cacheProvider.putToken(value: item.originalValue, token: item.token, dataType: item.dataType)
                                    cacheProvider.putValue(token: item.token, value: item.originalValue, dataType: item.dataType)
                                }
                            }
                        }
                        
                        logger.debug("Batch Tokenization successful", file: #file, line: #line)
                        return .success(decodedObject)
                    } catch (let error) {
                        logger.error("Failed to parse decrypted response: \(error.localizedDescription)", file: #file, line: #line)
                        return .failure(.batchTokenisationFalied)
                    }
                case .failure(message: let message):
                    logger.error("Failed to parse batch tokenization response: \(message)", file: #file, line: #line)
                    return .failure(.batchTokenisationFalied)
                }
            case .failure(_):
                logger.error("Batch Tokenization failed", file: #file, line: #line)
                return .failure(.invalidBatchTokenisationResponse)
            }
        } catch {
            return .failure(.batchTokenisationFalied)
        }
    }
    
    private func separateCachedValues(_ values: [String]) -> ([BatchTokenItem], [String]) {
        if !cacheProvider.isEnabled() {
            return ([], values)
        }
        
        var cachedResults: [BatchTokenItem] = []
        var uncachedValues: [String] = []
        
        for (_, value) in values.enumerated() {
            if let tokenDetails = cacheProvider.getToken(for: value) {
                cachedResults.append(BatchTokenItem(originalValue: value, token: tokenDetails.token, exists: true, newlyCreated: false, dataType: tokenDetails.dataType))
            } else {
                uncachedValues.append(value)
            }
        }
        
        return (cachedResults, uncachedValues)
    }
    
    // MARK: - Retry Logic
    
    private func performWithRetry<T>(
        operation: String,
        maxAttempts: Int,
        block: () async -> Result<T, ZeroPiiError>
    ) async -> Result<T, ZeroPiiError> {
        var lastError: ZeroPiiError = .networkError
        
        for attempt in 0..<maxAttempts {
            let result = await block()
            
            switch result {
            case .success:
                if attempt > 0 {
                    logger.info("Operation \(operation) succeeded after \(attempt + 1) attempts", file: #file, line: #line)
                }
                return result
                
            case .failure(let error):
                lastError = error
                if attempt == maxAttempts - 1 {
                    logger.error("Operation \(operation) failed after \(attempt + 1) attempts: \(error.localizedDescription)", file: #file, line: #line)
                    break
                }
                
                // Handle token refresh for 401 errors
                if error == .unauthorized {
                    logger.debug("Attempting token refresh for unauthorized 401 error", file: #file, line: #line)

                    let refreshResult = await authRepository.refreshAccessToken()
                    if case .failure(let refreshError) = refreshResult {
                        logger.error("Token refresh failed: \(refreshError.localizedDescription)", file: #file, line: #line)
                        return .failure(refreshError)
                    }
                }
                
                let delayMs = initialRetryDelayMs * (1 << attempt)
                logger.debug("Retrying operation \(operation) in \(delayMs)s (attempt \(attempt + 1)/\(maxAttempts))", file: #file, line: #line)
                
                try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            }
        }
        
        return .failure(lastError)
    }
}
