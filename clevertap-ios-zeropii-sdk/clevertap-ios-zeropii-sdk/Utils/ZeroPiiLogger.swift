//
//  ZeroPiiLogger.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 01/07/25.
//

import Foundation
import os.log

@objc public class ZeroPiiLogger: NSObject, ZeroPiiLoggerProtocol {

    private static let tag = "CT-ZeroPiiSDK"
    private static let maxLogLength = 4000

    @objc public var logLevel: ZeroPiiLogLevel = .off
    private let osLog = OSLog(subsystem: "CleverTap", category: tag)

    @objc public static let shared = ZeroPiiLogger()
    private override init() {}

    // MARK: - Public Logging Methods

    func debug(_ message: String, file: String = #file, line: Int = #line) {
        guard logLevel.rawValue >= ZeroPiiLogLevel.debug.rawValue else { return }
        log(message, level: .debug, file: file, line: line)
    }

    func info(_ message: String, file: String = #file, line: Int = #line) {
        guard logLevel.rawValue >= ZeroPiiLogLevel.info.rawValue else { return }
        log(message, level: .info, file: file, line: line)
    }

    func warning(_ message: String, file: String = #file, line: Int = #line) {
        guard logLevel.rawValue >= ZeroPiiLogLevel.info.rawValue else { return }
        log(message, level: .info, file: file, line: line, overrideType: .default)
    }

    func error(_ message: String, file: String = #file, line: Int = #line) {
        guard logLevel.rawValue >= ZeroPiiLogLevel.error.rawValue else { return }
        log(message, level: .error, file: file, line: line)
    }

    // MARK: - Private Methods

    private func log(_ message: String, level: ZeroPiiLogLevel, file: String, line: Int, overrideType: OSLogType? = nil) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(ZeroPiiLogger.tag)] \(fileName):\(line) - \(message)"
        let logType = overrideType ?? osLogType(for: level)

        if logMessage.count > ZeroPiiLogger.maxLogLength {
            logSplit(logMessage, type: logType)
        } else {
            os_log("%{public}@", log: osLog, type: logType, logMessage)
        }
    }

    private func logSplit(_ message: String, type: OSLogType) {
        var remaining = message
        while !remaining.isEmpty {
            let end = remaining.index(remaining.startIndex, offsetBy: min(ZeroPiiLogger.maxLogLength, remaining.count))
            let chunk = String(remaining[remaining.startIndex..<end])
            os_log("%{public}@", log: osLog, type: type, chunk)
            remaining = String(remaining[end...])
        }
    }

    private func osLogType(for level: ZeroPiiLogLevel) -> OSLogType {
        switch level {
        case .off:     return .default
        case .error:   return .error
        case .info:    return .info
        case .debug:   return .debug
        }
    }
}
