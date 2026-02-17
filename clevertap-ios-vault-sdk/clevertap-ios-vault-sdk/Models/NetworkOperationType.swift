//
//  NetworkOperationType.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 24/09/25.
//

import Foundation

public enum NetworkOperationType: String, CaseIterable {
    case tokenize = "tokenize"
    case detokenize = "detokenize"
    case batchTokenize = "batchTokenize"
    case batchDetokenize = "batchDetokenize"
}
