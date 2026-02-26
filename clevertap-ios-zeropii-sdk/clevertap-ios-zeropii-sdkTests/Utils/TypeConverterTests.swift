//
//  TypeConverterTests.swift
//  clevertap-ios-zeropii-sdkTests
//

import XCTest
@testable import clevertap_ios_zeropii_sdk

final class TypeConverterTests: XCTestCase {

    override func setUpWithError() throws {
        TypeConverterRegistry.initialize()
    }

    // MARK: - StringConverter

    func testStringConverter_returnsValueAsIs() {
        let converter = StringConverter()
        XCTAssertEqual(converter.toString("hello"), "hello")
        XCTAssertEqual(converter.toString(""), "")
        XCTAssertEqual(converter.toString("test@email.com"), "test@email.com")
        XCTAssertEqual(converter.toString("special !@#$%"), "special !@#$%")
    }

    func testStringConverter_typeName() {
        XCTAssertEqual(StringConverter().typeName, "string")
    }

    // MARK: - IntConverter

    func testIntConverter_convertsToString() {
        let converter = IntConverter()
        XCTAssertEqual(converter.toString(0), "0")
        XCTAssertEqual(converter.toString(42), "42")
        XCTAssertEqual(converter.toString(-1), "-1")
        XCTAssertEqual(converter.toString(Int.max), String(Int.max))
        XCTAssertEqual(converter.toString(Int.min), String(Int.min))
    }

    func testIntConverter_typeName() {
        XCTAssertEqual(IntConverter().typeName, "integer")
    }

    // MARK: - Int64Converter

    func testInt64Converter_convertsToString() {
        let converter = Int64Converter()
        XCTAssertEqual(converter.toString(0), "0")
        XCTAssertEqual(converter.toString(Int64.max), String(Int64.max))
        XCTAssertEqual(converter.toString(Int64.min), String(Int64.min))
        XCTAssertEqual(converter.toString(Int64(9_999_999_999)), "9999999999")
    }

    func testInt64Converter_typeName() {
        XCTAssertEqual(Int64Converter().typeName, "long")
    }

    // MARK: - FloatConverter

    func testFloatConverter_convertsToString() {
        let converter = FloatConverter()
        XCTAssertEqual(converter.toString(Float(0.0)), String(Float(0.0)))
        XCTAssertEqual(converter.toString(Float(3.14)), String(Float(3.14)))
        XCTAssertEqual(converter.toString(Float(-1.5)), String(Float(-1.5)))
    }

    func testFloatConverter_typeName() {
        XCTAssertEqual(FloatConverter().typeName, "float")
    }

    // MARK: - DoubleConverter

    func testDoubleConverter_convertsToString() {
        let converter = DoubleConverter()
        XCTAssertEqual(converter.toString(0.0), "0.0")
        XCTAssertEqual(converter.toString(3.14159), "3.14159")
        XCTAssertEqual(converter.toString(-100.5), "-100.5")
    }

    func testDoubleConverter_typeName() {
        XCTAssertEqual(DoubleConverter().typeName, "double")
    }

    // MARK: - BoolConverter

    func testBoolConverter_trueConvertsToString() {
        let converter = BoolConverter()
        XCTAssertEqual(converter.toString(true), "true")
    }

    func testBoolConverter_falseConvertsToString() {
        let converter = BoolConverter()
        XCTAssertEqual(converter.toString(false), "false")
    }

    func testBoolConverter_typeName() {
        XCTAssertEqual(BoolConverter().typeName, "boolean")
    }

    // MARK: - TypeConverterRegistry: Initialize

    func testRegistry_initialize_registersAllBuiltInTypes() {
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: String.self))
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: Int.self))
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: Int64.self))
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: Float.self))
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: Double.self))
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: Bool.self))
    }

    func testRegistry_initialize_isIdempotent() {
        // Calling initialize twice should not throw or corrupt state
        TypeConverterRegistry.initialize()
        TypeConverterRegistry.initialize()
        XCTAssertNotNil(TypeConverterRegistry.getConverter(for: String.self))
    }

    // MARK: - TypeConverterRegistry: getConverter

    func testRegistry_getConverter_string_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: String.self)
        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString("test"), "test")
    }

    func testRegistry_getConverter_int_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: Int.self)
        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString(99), "99")
    }

    func testRegistry_getConverter_int64_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: Int64.self)
        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString(Int64(12345678901)), "12345678901")
    }

    func testRegistry_getConverter_float_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: Float.self)
        XCTAssertNotNil(converter)
        XCTAssertNotNil(converter?.toString(Float(1.5)))
    }

    func testRegistry_getConverter_double_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: Double.self)
        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString(2.5), "2.5")
    }

    func testRegistry_getConverter_bool_convertsCorrectly() {
        let converter = TypeConverterRegistry.getConverter(for: Bool.self)
        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString(true), "true")
        XCTAssertEqual(converter?.toString(false), "false")
    }

    func testRegistry_getConverter_unregisteredType_returnsNil() {
        struct UnknownType {}
        let converter = TypeConverterRegistry.getConverter(for: UnknownType.self)
        XCTAssertNil(converter)
    }

    // MARK: - TypeConverterRegistry: Custom Registration

    func testRegistry_register_customConverter_isRetrievable() {
        struct CustomID {}
        struct CustomIDConverter: TypeConverter {
            typealias T = CustomID
            func toString(_ value: CustomID) -> String { return "custom-id" }
            var typeName: String { "customid" }
        }

        TypeConverterRegistry.register(CustomID.self, converter: CustomIDConverter())
        let converter = TypeConverterRegistry.getConverter(for: CustomID.self)

        XCTAssertNotNil(converter)
        XCTAssertEqual(converter?.toString(CustomID()), "custom-id")
    }

    func testRegistry_register_overridesExistingConverter() {
        // Register a custom string converter that uppercases
        struct UpperStringConverter: TypeConverter {
            typealias T = String
            func toString(_ value: String) -> String { return value.uppercased() }
            var typeName: String { "string" }
        }

        TypeConverterRegistry.register(String.self, converter: UpperStringConverter())
        let converter = TypeConverterRegistry.getConverter(for: String.self)

        XCTAssertEqual(converter?.toString("hello"), "HELLO")

        // Restore the original converter for other tests
        TypeConverterRegistry.register(String.self, converter: StringConverter())
    }
}
