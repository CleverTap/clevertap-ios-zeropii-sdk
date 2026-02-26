//
//  TypeConverter.swift
//  clevertap-ios-zeropii-sdk
//
//  Created by Nishant Kumar on 02/02/26.
//

import Foundation

/// Protocol for converting between generic types and strings
protocol TypeConverter<T> {
    associatedtype T

    /// Converts a value to a string representation
    func toString(_ value: T) -> String

    /// The name of the type this converter handles
    var typeName: String { get }
}

// MARK: - Type Eraser for TypeConverter

/// Type-erased wrapper for TypeConverter to store in registry
class AnyTypeConverter<T> {
    private let _toString: (T) -> String
    private let _typeName: String

    init<C: TypeConverter>(_ converter: C) where C.T == T {
        self._toString = converter.toString
        self._typeName = converter.typeName
    }

    func toString(_ value: T) -> String {
        return _toString(value)
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

    var typeName: String {
        return "boolean"
    }
}
