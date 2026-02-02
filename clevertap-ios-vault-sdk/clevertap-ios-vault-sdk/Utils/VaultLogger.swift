//
//  VaultLogger.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation
import os.log

@objc public class VaultLogger: NSObject, VaultLoggerProtocol {
    @objc public var logLevel: VaultLogLevel = .warning
    private var osLog = OSLog(subsystem: "CleverTap", category: "VaultSDK")
    
    @objc public static let shared = VaultLogger()
    private override init() {}
    
    func debug(_ message: String, file: String, function: String, line: Int) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String, function: String, line: Int) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String, function: String, line: Int) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String, function: String, line: Int) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
        
    private func log(_ message: String, level: VaultLogLevel, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(fileName):\(line) \(function) - \(message)"
        
        switch level {
            case .off:
                break
            case .debug:
                os_log(.debug, log: osLog, "%{public}@", logMessage)
            case .info:
                os_log(.info, log: osLog, "%{public}@", logMessage)
            case .warning:
                os_log(.default, log: osLog, "%{public}@", logMessage)
            case .error:
                os_log(.error, log: osLog, "%{public}@", logMessage)
        }
    }
}
