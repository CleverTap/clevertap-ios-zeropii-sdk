//
//  VaultSDK.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 02/02/26.
//

import Foundation

/// The main entry point for the Vault SDK, which provides tokenization services
/// for sensitive data like PII (Personally Identifiable Information).
@objc public class VaultSDK: NSObject {
    
    // MARK: - Private Properties
    
    private let clientId: String
    private let clientSecret: String
    private let apiUrl: String
    private let authUrl: String
    private let logLevel: VaultLogLevel
    
    internal var sdkQueue: DispatchQueue
    internal var tokenRepository: TokenRepository!
    internal var authRepository: AuthRepositoryImpl!
    private var encryptionManager: EncryptionManager!
    private var tokenCacheManager: TokenCacheManager!
    private var logger: VaultLogger!
    
    // MARK: - Singleton
    
    @objc public static var shared: VaultSDK {
        guard let instance = _instance else {
            fatalError("VaultSDK is not initialized. Call initialize() first.")
        }
        return instance
    }
    
    private static var _instance: VaultSDK?
    
    // MARK: - Initialization
    
    private init(
        clientId: String,
        clientSecret: String,
        apiUrl: String,
        authUrl: String,
        logLevel: VaultLogLevel
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.apiUrl = apiUrl
        self.authUrl = authUrl
        self.logLevel = logLevel
        self.sdkQueue = DispatchQueue(label: "com.clevertap.vault.sdk", qos: .utility)
        
        super.init()
        initialize()
    }
    
    private func initialize() {
        logger = VaultLogger.shared
        logger.logLevel = logLevel
        logger.debug("Initializing VaultSDK", file: #file, function: #function, line: #line)
        
        // Create network provider
        let networkConfig = NetworkConfiguration(tokenizationURL: apiUrl, authURL: authUrl)
        let networkProvider = NetworkManager(configuration: networkConfig, logger: logger)
        
        // Setup encryption manager if enabled
        encryptionManager = EncryptionManager(enabled: true, logger: logger)
        
        // Initialize token cache if enabled
        tokenCacheManager = TokenCacheManager(enabled: true)
        
        // Create repositories
        authRepository = AuthRepositoryImpl(
            networkProvider: networkProvider,
            clientId: clientId,
            clientSecret: clientSecret,
            logger: logger
        )
        
        tokenRepository = TokenRepositoryImpl(
            networkProvider: networkProvider,
            authRepository: authRepository,
            cacheProvider: tokenCacheManager,
            logger: logger
        )
        
        logger.debug("VaultSDK initialization complete", file: #file, function: #function, line: #line)
    }
    
    // MARK: - Public Static Initialization
    
    @objc public static func initialize(
        clientId: String,
        clientSecret: String,
        apiUrl: String,
        authUrl: String,
        logLevel: VaultLogLevel = .off
    ) -> VaultSDK {
        if _instance == nil {
            objc_sync_enter(self)
            if _instance == nil {
                _instance = VaultSDK(
                    clientId: clientId,
                    clientSecret: clientSecret,
                    apiUrl: apiUrl,
                    authUrl: authUrl,
                    logLevel: logLevel
                )
            }
            objc_sync_exit(self)
        }
        return _instance!
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
   
    /// Clears the token cache
    @objc public func clearCache() {
        logger.debug("Clearing token cache", file: #file, function: #function, line: #line)
        tokenCacheManager.clear()
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
                self.logger.debug("Tokenizing \(typeName) value", file: #file, function: #function, line: #line)
                
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
                self.logger.debug("Tokenization result: \(typeName) value: \(repoResult)", file: #file, function: #function, line: #line)
                
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
                self.logger.debug("Batch tokenizing \(values.count) \(typeName) values", file: #file, function: #function, line: #line)
                
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
                self.logger.debug("Batch tokenization result: \(typeName) values: \(repoResult)", file: #file, function: #function, line: #line)
                
                let batchTokenizeResult = BatchTokenizeResult(result: repoResult)
                callback(batchTokenizeResult)
            }
        }
    }
}
