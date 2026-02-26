//
//  ZeroPiiLoggerProtocol.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation

/// Higher raw value = more verbose.
@objc public enum ZeroPiiLogLevel: Int {
    case off     = 0   // No logging
    case error   = 1   // Only errors
    case info    = 2   // Errors + Info + Warning
    case debug   = 3   // Errors + Info + Warning + Debug
}

/// Protocol defining logging operations for the ZeroPii SDK
protocol ZeroPiiLoggerProtocol {
    /// Current log level
    var logLevel: ZeroPiiLogLevel { get set }

    /// Logs a debug message (for development and troubleshooting)
    func debug(_ message: String, file: String, line: Int)

    /// Logs an informational message (general information)
    func info(_ message: String, file: String, line: Int)

    /// Logs a warning message (potential issues)
    func warning(_ message: String, file: String, line: Int)

    /// Logs an error message (serious problems)
    func error(_ message: String, file: String, line: Int)
}
