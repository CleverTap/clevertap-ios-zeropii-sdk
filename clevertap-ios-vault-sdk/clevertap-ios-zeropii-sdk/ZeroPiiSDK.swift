//
//  ZeroPiiSDK.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 02/02/26.
//

import Foundation

/// The main entry point for the ZeroPii SDK, which provides tokenization services
/// for sensitive data like PII (Personally Identifiable Information).
@objc public class ZeroPiiSDK: NSObject {
    
    // MARK: - Private Properties

    private let tokenProvider: AccessTokenProvider
    private let apiUrl: String
    private let logLevel: ZeroPiiLogLevel

    internal var sdkQueue: DispatchQueue
    internal var tokenRepository: TokenRepository!
    internal var authRepository: AuthRepository!
    private var encryptionManager: EncryptionManager!
    private var logger: ZeroPiiLogger!

    // MARK: - Singleton

    @objc public static var shared: ZeroPiiSDK {
        return getInstance()
    }

    private static var _instance: ZeroPiiSDK?

    // MARK: - Initialization

    private init(
        tokenProvider: AccessTokenProvider,
        apiUrl: String,
        logLevel: ZeroPiiLogLevel
    ) {
        self.tokenProvider = tokenProvider
        self.apiUrl = apiUrl
        self.logLevel = logLevel
        self.sdkQueue = DispatchQueue(label: "com.clevertap.zeropii.sdk", qos: .utility)

        super.init()
        initialize()
    }

    private func initialize() {
        logger = ZeroPiiLogger.shared
        logger.logLevel = logLevel
        logger.debug("Initializing ZeroPiiSDK", file: #file, line: #line)

        // Create network provider
        let networkConfig = NetworkConfiguration(tokenizationBaseURL: apiUrl)
        let networkProvider = NetworkManager(configuration: networkConfig, logger: logger)

        // Setup encryption manager
        encryptionManager = EncryptionManager(enabled: true, logger: logger)

        // Create repositories
        authRepository = AuthRepositoryImpl(
            tokenProvider: tokenProvider,
            logger: logger
        )

        tokenRepository = TokenRepositoryImpl(
            networkProvider: networkProvider,
            authRepository: authRepository,
            encryptionManager: encryptionManager,
            logger: logger
        )

        TypeConverterRegistry.initialize()
        logger.debug("ZeroPiiSDK initialization complete", file: #file, line: #line)
    }

    // MARK: - Public Static Initialization

    /// Initializes the ZeroPiiSDK with an app-provided token provider.
    ///
    /// This convenience overload uses the default log level (`.off`) and is intended for
    /// Objective-C callers, which cannot use Swift default parameter values.
    ///
    /// - Parameters:
    ///   - tokenProvider: An implementation of `AccessTokenProvider` that supplies bearer tokens.
    ///   - apiUrl: The base URL for the tokenization API.
    /// - Returns: The initialized `ZeroPiiSDK` singleton instance.
    @discardableResult
    @objc public static func initialize(
        tokenProvider: AccessTokenProvider,
        apiUrl: String
    ) -> ZeroPiiSDK {
        return initialize(tokenProvider: tokenProvider, apiUrl: apiUrl, logLevel: .off)
    }

    /// Initializes the ZeroPiiSDK with an app-provided token provider.
    ///
    /// - Parameters:
    ///   - tokenProvider: An implementation of ``AccessTokenProvider`` that supplies bearer tokens.
    ///   - apiUrl: The base URL for the tokenization API.
    ///   - logLevel: The desired log verbosity (default: `.off`).
    /// - Returns: The initialized ``ZeroPiiSDK`` singleton instance.
    @discardableResult
    @objc public static func initialize(
        tokenProvider: AccessTokenProvider,
        apiUrl: String,
        logLevel: ZeroPiiLogLevel = .off
    ) -> ZeroPiiSDK {
        if _instance == nil {
            objc_sync_enter(self)
            if _instance == nil {
                _instance = ZeroPiiSDK(
                    tokenProvider: tokenProvider,
                    apiUrl: apiUrl,
                    logLevel: logLevel
                )
            }
            objc_sync_exit(self)
        }
        return _instance!
    }

    /// Gets the ZeroPiiSDK instance.
    /// - Returns: The ZeroPiiSDK instance
    /// - Throws: Fatal error if not initialized
    @objc public static func getInstance() -> ZeroPiiSDK {
        guard let instance = _instance else {
            fatalError("ZeroPiiSDK is not initialized. Call initialize() first.")
        }
        return instance
    }
    
    // MARK: - Tokenization Methods
        
    /// Tokenizes a String value
    /// - Parameters:
    ///   - value: The String value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeString(_ value: String, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: String.self, callback: callback)
    }
    
    /// Tokenizes an Int value
    /// - Parameters:
    ///   - value: The Int value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeInt(_ value: Int, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: Int.self, callback: callback)
    }
    
    /// Tokenizes an Int64 (Long) value
    /// - Parameters:
    ///   - value: The Int64 value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeLong(_ value: Int64, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: Int64.self, callback: callback)
    }
    
    /// Tokenizes a Float value
    /// - Parameters:
    ///   - value: The Float value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeFloat(_ value: Float, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: Float.self, callback: callback)
    }
    
    /// Tokenizes a Double value
    /// - Parameters:
    ///   - value: The Double value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeDouble(_ value: Double, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: Double.self, callback: callback)
    }
    
    /// Tokenizes a Boolean value
    /// - Parameters:
    ///   - value: The Boolean value to tokenize
    ///   - callback: The callback to receive the result
    @objc public func tokenizeBool(_ value: Bool, callback: @escaping (TokenizeResult) -> Void) {
        performTokenization(value: value, type: Bool.self, callback: callback)
    }
    
    // MARK: - Batch Tokenization Methods
        
    /// Tokenizes multiple String values in a single batch operation
    /// - Parameters:
    ///   - values: The list of String values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeStringValues(_ values: [String], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: String.self, callback: callback)
    }
    
    /// Tokenizes multiple Int values in a single batch operation
    /// - Parameters:
    ///   - values: The list of Int values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeIntValues(_ values: [Int], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: Int.self, callback: callback)
    }
    
    /// Tokenizes multiple Int64 (Long) values in a single batch operation
    /// - Parameters:
    ///   - values: The list of Int64 values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeLongValues(_ values: [Int64], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: Int64.self, callback: callback)
    }
    
    /// Tokenizes multiple Float values in a single batch operation
    /// - Parameters:
    ///   - values: The list of Float values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeFloatValues(_ values: [Float], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: Float.self, callback: callback)
    }
    
    /// Tokenizes multiple Double values in a single batch operation
    /// - Parameters:
    ///   - values: The list of Double values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeDoubleValues(_ values: [Double], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: Double.self, callback: callback)
    }
    
    /// Tokenizes multiple Boolean values in a single batch operation
    /// - Parameters:
    ///   - values: The list of Boolean values to tokenize
    ///   - callback: The callback to receive the result
    @objc public func batchTokenizeBoolValues(_ values: [Bool], callback: @escaping (BatchTokenizeResult) -> Void) {
        performBatchTokenization(values: values, type: Bool.self, callback: callback)
    }
   
    // MARK: - Private Methods
    
    /// Internal method to perform tokenization with type conversion
    private func performTokenization<T>(
        value: T,
        type: T.Type,
        callback: @escaping (TokenizeResult) -> Void
    ) {
        sdkQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                let typeName = String(describing: type)
                self.logger.debug("Tokenizing \(typeName) value", file: #file, line: #line)
                
                guard let converter = TypeConverterRegistry.getConverter(for: type) else {
                    let tokenizeResult = TokenizeResult(result: .error(message: "Unsupported type: \(typeName)"))
                    callback(tokenizeResult)
                    return
                }
                
                // Convert typed value to string for repository layer
                let stringValue = converter.toString(value)
                
                // Call repository with string value
                let repoResult = await self.tokenRepository.tokenize(stringValue)
                
                // Convert repository result to public result
                let tokenizeResult = TokenizeResult(result: repoResult)
                self.logger.debug("Tokenization result: \(typeName) value: \(repoResult)", file: #file, line: #line)
                
                callback(tokenizeResult)
            }
        }
    }

    /// Internal method to perform batch tokenization
    private func performBatchTokenization<T>(
            values: [T],
            type: T.Type,
            callback: @escaping (BatchTokenizeResult) -> Void
    ) {
        sdkQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                if values.isEmpty {
                    let result = BatchTokenResult.error(message: "Batch tokenize request contains no values")
                    let batchTokenizeResult = BatchTokenizeResult(result: result)
                    callback(batchTokenizeResult)
                    return
                }
                
                let typeName = String(describing: type)
                self.logger.debug("Batch tokenizing \(values.count) \(typeName) values", file: #file, line: #line)
                
                guard let converter = TypeConverterRegistry.getConverter(for: type) else {
                    let result = BatchTokenResult.error(message: "Unsupported type: \(typeName)")
                    let batchTokenizeResult = BatchTokenizeResult(result: result)
                    callback(batchTokenizeResult)
                    return
                }
                
                // Convert typed values to strings for repository layer
                let stringValues = values.map { converter.toString($0) }
                
                // Call repository with string values
                let repoResult = await self.tokenRepository.batchTokenize(stringValues)
                
                // Convert repository result to public result
                self.logger.debug("Batch tokenization result: \(typeName) values: \(repoResult)", file: #file, line: #line)
                
                let batchTokenizeResult = BatchTokenizeResult(result: repoResult)
                callback(batchTokenizeResult)
            }
        }
    }

}
