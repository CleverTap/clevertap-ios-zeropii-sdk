//
//  TokenizeResults.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 02/02/26.
//

import Foundation

@objc public class TokenizeResult: NSObject {
    @objc public let isSuccess: Bool
    @objc public let token: String?
    @objc public let exists: Bool
    @objc public let newlyCreated: Bool
    @objc public let dataType: String?
    @objc public let errorMessage: String?
    
    internal init(result: TokenResult) {
        switch result {
        case .success(let token, let exists, let newlyCreated, let dataType):
            self.isSuccess = true
            self.token = token
            self.exists = exists
            self.newlyCreated = newlyCreated
            self.dataType = dataType
            self.errorMessage = nil
            
        case .error(let message):
            self.isSuccess = false
            self.token = nil
            self.exists = false
            self.newlyCreated = false
            self.dataType = nil
            self.errorMessage = message
        }
        super.init()
    }
}

@objc public class BatchTokenizeResult: NSObject {
    @objc public let isSuccess: Bool
    @objc public let results: [BatchTokenItem]
    @objc public let summary: BatchTokenizeSummary?
    @objc public let errorMessage: String?

    internal init(result: BatchTokenResult) {
        switch result {
        case .success(let results, let summary):
            self.isSuccess = true
            self.results = results
            self.summary = summary
            self.errorMessage = nil

        case .error(let message):
            self.isSuccess = false
            self.results = []
            self.summary = nil
            self.errorMessage = message
        }
        super.init()
    }
}

