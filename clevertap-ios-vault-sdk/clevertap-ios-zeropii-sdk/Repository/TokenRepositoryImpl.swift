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
    private let encryptionManager: EncryptionManager
    private let logger: ZeroPiiLogger
    private let initialRetryDelayMs: Int = 1000
    private let maxBatchSizeTokenize: Int = 1000

    /// Flag to disable encryption for subsequent requests after a 419 backend decryption failure
    private var encryptionDisabledDueToFailure: Bool = false

    // MARK: - Initialization
    init(networkProvider: NetworkProvider,
        authRepository: AuthRepository,
        encryptionManager: EncryptionManager,
        logger: ZeroPiiLogger = ZeroPiiLogger.shared) {

        self.networkProvider = networkProvider
        self.authRepository = authRepository
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

    public func batchTokenize(_ values: [String]) async -> BatchTokenResult {
        guard !values.isEmpty else {
            logger.warning("Batch tokenize request contains no values", file: #file, line: #line)
            return .error(message: "Empty values passed")
        }

        guard values.count <= maxBatchSizeTokenize else {
            logger.error("Batch size \(values.count) exceeds maximum \(maxBatchSizeTokenize)", file: #file, line: #line)
            return .error(message: "Batch size exceeds maximum limit")
        }

        let result = await performWithRetry(operation: "batchTokenize", maxAttempts: 1) {
            await self.performBatchTokenization(values: values)
        }

        switch result {
        case .success(let response):
            return .success(results: response.results,
                            summary: response.summary)
        case .failure(let error):
            return .error(message: error.localizedDescription)
        }
    }

    // MARK: - Private Implementation Methods

    private func performTokenization(value: String) async -> Result<TokenizeResponse, ZeroPiiError> {
        let tokenResult = await authRepository.getAccessToken()
        guard case .success(let accessToken) = tokenResult else {
            logger.error("Failed to get access token for tokenization", file: #file, line: #line)
            return .failure(.authenticationFailed)
        }

        // If encryption was previously disabled due to 419, go straight to plain text
        if encryptionDisabledDueToFailure {
            logger.debug("Encryption is disabled due to previous failure, falling back to non-encrypted tokenization", file: #file, line: #line)
            return await performPlainTokenization(value: value, accessToken: accessToken)
        }

        // Try encrypted request
        let request = TokenizeRequest(value: value)
        guard let encryptedRequest = encryptionManager.createEncryptedRequest(request) else {
            // Fallback 1: Encryption of request failed, fall back to plain text
            logger.error("Encryption failed, falling back to non-encrypted tokenization", file: #file, line: #line)
            return await performPlainTokenization(value: value, accessToken: accessToken)
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
            case .failure(let error):
                // Fallback 2: Backend returned 419 (decryption failure)
                if error == .decryptionFailed {
                    logger.warning("Received 419 - Backend decryption failure, disabling encryption and falling back to non-encrypted requests", file: #file, line: #line)
                    encryptionDisabledDueToFailure = true
                    return await performPlainTokenization(value: value, accessToken: accessToken)
                }
                logger.error("Tokenisation failed", file: #file, line: #line)
                return .failure(error)
            }
        } catch {
            return .failure(.tokenisationFalied)
        }
    }

    private func performPlainTokenization(value: String, accessToken: String) async -> Result<TokenizeResponse, ZeroPiiError> {
        let request = TokenizeRequest(value: value)
        do {
            let networkResult = try await networkProvider.tokenizePlain(request, accessToken: accessToken)

            switch networkResult {
            case .success(let response):
                logger.debug("Non-encrypted tokenization successful", file: #file, line: #line)
                return .success(response)
            case .failure(let error):
                logger.error("Non-encrypted tokenisation failed", file: #file, line: #line)
                return .failure(error)
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

        // If encryption was previously disabled due to 419, go straight to plain text
        if encryptionDisabledDueToFailure {
            logger.debug("Encryption is disabled due to previous failure, falling back to non-encrypted batch tokenization", file: #file, line: #line)
            return await performPlainBatchTokenization(values: values, accessToken: accessToken)
        }

        // Try encrypted request
        let request = BatchTokenizeRequest(values: values)
        guard let encryptedRequest = encryptionManager.createEncryptedRequest(request) else {
            // Fallback 1: Encryption of request failed, fall back to plain text
            logger.error("Encryption failed, falling back to non-encrypted batch tokenization", file: #file, line: #line)
            return await performPlainBatchTokenization(values: values, accessToken: accessToken)
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
            case .failure(let error):
                // Fallback 2: Backend returned 419 (decryption failure)
                if error == .decryptionFailed {
                    logger.warning("Received 419 - Backend decryption failure, disabling encryption and falling back to non-encrypted requests", file: #file, line: #line)
                    encryptionDisabledDueToFailure = true
                    return await performPlainBatchTokenization(values: values, accessToken: accessToken)
                }
                logger.error("Batch Tokenization failed", file: #file, line: #line)
                return .failure(error)
            }
        } catch {
            return .failure(.batchTokenisationFalied)
        }
    }

    private func performPlainBatchTokenization(values: [String], accessToken: String) async -> Result<BatchTokenizeResponse, ZeroPiiError> {
        let request = BatchTokenizeRequest(values: values)
        do {
            let networkResult = try await networkProvider.batchTokenizePlain(request, accessToken: accessToken)

            switch networkResult {
            case .success(let response):
                logger.debug("Non-encrypted batch tokenization successful", file: #file, line: #line)
                return .success(response)
            case .failure(let error):
                logger.error("Non-encrypted batch tokenisation failed", file: #file, line: #line)
                return .failure(error)
            }
        } catch {
            return .failure(.batchTokenisationFalied)
        }
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
