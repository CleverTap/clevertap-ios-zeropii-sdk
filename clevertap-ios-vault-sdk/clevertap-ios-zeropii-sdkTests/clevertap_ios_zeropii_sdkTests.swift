//
//  clevertap_ios_zeropii_sdkTests.swift
//  clevertap-ios-zeropii-sdkTests
//
//  Created by Nishant Kumar on 05/06/25.
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

// Unit tests are organized into separate files per component:
//
//  ZeroPiiErrorTests.swift          - Error cases, raw values, descriptions
//  NetworkRequestBuilderTests.swift - HTTP request construction
//  NetworkResponseHandlerTests.swift - HTTP response parsing and error mapping
//  AuthRepositoryImplTests.swift    - Token caching, refresh, validity
//  EncryptionManagerTests.swift     - Encrypt/decrypt, session key, fallback
//  TokenRepositoryImplTests.swift   - Tokenization with encryption fallbacks (419, disabled)
//  TypeConverterTests.swift         - Type converter registry
//  StringOrIntTests.swift           - StringOrInt codable union type
//  TokenModelsTests.swift           - Request/response model encoding and decoding
//  TokenizeResultsTests.swift       - Public result wrapper classes
