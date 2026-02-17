//
//  ZeroPiiLoggerProtocol.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

@objc public enum ZeroPiiLogLevel: Int {
    case off = -1
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var description: String {
        switch self {
            case .off: return "OFF"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
        }
    }
}

/// Protocol defining logging operations for the ZeroPii SDK
protocol ZeroPiiLoggerProtocol {
    /// Current log level
    var logLevel: ZeroPiiLogLevel { get set }
    
    /// Logs a debug message (for development and troubleshooting)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file where log was called
    ///   - function: Function where log was called
    ///   - line: Line number where log was called
    func debug(_ message: String, file: String, function: String, line: Int)
    
    /// Logs an informational message (general information)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file where log was called
    ///   - function: Function where log was called
    ///   - line: Line number where log was called
    func info(_ message: String, file: String, function: String, line: Int)
    
    /// Logs a warning message (potential issues)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file where log was called
    ///   - function: Function where log was called
    ///   - line: Line number where log was called
    func warning(_ message: String, file: String, function: String, line: Int)
    
    /// Logs an error message (serious problems)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file where log was called
    ///   - function: Function where log was called
    ///   - line: Line number where log was called
    func error(_ message: String, file: String, function: String, line: Int)
}
