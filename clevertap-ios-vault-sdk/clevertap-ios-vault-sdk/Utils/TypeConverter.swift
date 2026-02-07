//
//  TypeConverter.swift
//  clevertap-ios-vault-sdk
//
//  Created by Nishant Kumar on 02/02/26.
//

import Foundation

/// Protocol for converting between generic types and strings
protocol TypeConverter<T> {
    associatedtype T
    
    /// Converts a value to a string representation
    func toString(_ value: T) -> String
    
    /// Converts a string back to the original type
    /// - Throws: Error if conversion fails
    func fromString(_ value: String) throws -> T
    
    /// Converts a string back to the original type, returning nil if conversion fails
    func fromStringNullable(_ value: String?) -> T?
    
    /// The name of the type this converter handles
    var typeName: String { get }
}

// MARK: - Type Eraser for TypeConverter

/// Type-erased wrapper for TypeConverter to store in registry
class AnyTypeConverter<T> {
    private let _toString: (T) -> String
    private let _fromString: (String) throws -> T
    private let _fromStringNullable: (String?) -> T?
    private let _typeName: String
    
    init<C: TypeConverter>(_ converter: C) where C.T == T {
        self._toString = converter.toString
        self._fromString = converter.fromString
        self._fromStringNullable = converter.fromStringNullable
        self._typeName = converter.typeName
    }
    
    func toString(_ value: T) -> String {
        return _toString(value)
    }
    
    func fromString(_ value: String) throws -> T {
        return try _fromString(value)
    }
    
    func fromStringNullable(_ value: String?) -> T? {
        return _fromStringNullable(value)
    }
    
    var typeName: String {
        return _typeName
    }
}

// MARK: - Type Converter Registry

/// Registry of type converters for supported data types
class TypeConverterRegistry {
    
    private static var converters: [String: Any] = [:]
    private static let lock = NSLock()
    
    /// Initialize built-in converters
    static func initialize() {
        if converters.isEmpty {
            register(String.self, converter: StringConverter())
            register(Int.self, converter: IntConverter())
            register(Int64.self, converter: Int64Converter())
            register(Float.self, converter: FloatConverter())
            register(Double.self, converter: DoubleConverter())
            register(Bool.self, converter: BoolConverter())
        }
    }
    
    /// Register a converter for a specific type
    static func register<T, C: TypeConverter>(_ type: T.Type, converter: C) where C.T == T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        converters[key] = AnyTypeConverter(converter)
    }
    
    /// Get a converter for a specific type
    static func getConverter<T>(for type: T.Type) -> AnyTypeConverter<T>? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        return converters[key] as? AnyTypeConverter<T>
    }
}

// MARK: - Built-in Type Converters

/// Converter for String type
struct StringConverter: TypeConverter {
    typealias T = String
    
    func toString(_ value: String) -> String {
        return value
    }
    
    func fromString(_ value: String) throws -> String {
        return value
    }
    
    func fromStringNullable(_ value: String?) -> String? {
        return value
    }
    
    var typeName: String {
        return "string"
    }
}

/// Converter for Int type
struct IntConverter: TypeConverter {
    typealias T = Int
    
    func toString(_ value: Int) -> String {
        return String(value)
    }
    
    func fromString(_ value: String) throws -> Int {
        guard let intValue = Int(value) else {
            throw NSError(
                domain: "TypeConverterError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Cannot convert '\(value)' to Int"]
            )
        }
        return intValue
    }
    
    func fromStringNullable(_ value: String?) -> Int? {
        guard let value = value else { return nil }
        return Int(value)
    }
    
    var typeName: String {
        return "integer"
    }
}

/// Converter for Int64 (Long) type
struct Int64Converter: TypeConverter {
    typealias T = Int64
    
    func toString(_ value: Int64) -> String {
        return String(value)
    }
    
    func fromString(_ value: String) throws -> Int64 {
        guard let int64Value = Int64(value) else {
            throw NSError(
                domain: "TypeConverterError",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Cannot convert '\(value)' to Int64"]
            )
        }
        return int64Value
    }
    
    func fromStringNullable(_ value: String?) -> Int64? {
        guard let value = value else { return nil }
        return Int64(value)
    }
    
    var typeName: String {
        return "long"
    }
}

/// Converter for Float type
struct FloatConverter: TypeConverter {
    typealias T = Float
    
    func toString(_ value: Float) -> String {
        return String(value)
    }
    
    func fromString(_ value: String) throws -> Float {
        guard let floatValue = Float(value) else {
            throw NSError(
                domain: "TypeConverterError",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Cannot convert '\(value)' to Float"]
            )
        }
        return floatValue
    }
    
    func fromStringNullable(_ value: String?) -> Float? {
        guard let value = value else { return nil }
        return Float(value)
    }
    
    var typeName: String {
        return "float"
    }
}

/// Converter for Double type
struct DoubleConverter: TypeConverter {
    typealias T = Double
    
    func toString(_ value: Double) -> String {
        return String(value)
    }
    
    func fromString(_ value: String) throws -> Double {
        guard let doubleValue = Double(value) else {
            throw NSError(
                domain: "TypeConverterError",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Cannot convert '\(value)' to Double"]
            )
        }
        return doubleValue
    }
    
    func fromStringNullable(_ value: String?) -> Double? {
        guard let value = value else { return nil }
        return Double(value)
    }
    
    var typeName: String {
        return "double"
    }
}

/// Converter for Bool type
struct BoolConverter: TypeConverter {
    typealias T = Bool
    
    func toString(_ value: Bool) -> String {
        return String(value)
    }
    
    func fromString(_ value: String) throws -> Bool {
        switch value.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            throw NSError(
                domain: "TypeConverterError",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey: "Cannot convert '\(value)' to Bool"]
            )
        }
    }
    
    func fromStringNullable(_ value: String?) -> Bool? {
        guard let value = value else { return nil }
        
        switch value.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
    
    var typeName: String {
        return "boolean"
    }
}
