//
//  ZeroPIIModels.swift
//  ZeroPIISample
//
//  Created by Nishant Kumar on 05/02/26.
//

import Foundation
import SwiftUI
import clevertap_ios_zeropii_sdk

// MARK: - Data Types
enum DataType: String, CaseIterable {
    case string
    case int
    case long
    case float
    case double
    case boolean
    
    var displayName: String {
        switch self {
        case .string: return "String"
        case .int: return "Int"
        case .long: return "Long"
        case .float: return "Float"
        case .double: return "Double"
        case .boolean: return "Boolean"
        }
    }
    
    var icon: String {
        switch self {
        case .string: return "📝"
        case .int: return "🔢"
        case .long: return "📊"
        case .float: return "💰"
        case .double: return "🎯"
        case .boolean: return "✅"
        }
    }
}

// MARK: - Operation Types
enum OperationType: String, CaseIterable {
    case single
    case batch
    
    var displayName: String {
        switch self {
        case .single: return "Single"
        case .batch: return "Batch"
        }
    }
}

// MARK: - Token Display Items
enum TokenDisplayItem: Identifiable {
    case loading(String)
    case singleTokenize(originalValue: String, token: String, exists: Bool, newlyCreated: Bool, dataType: String, inputDataType: DataType)
    case batchTokenize(results: [BatchTokenItem], summary: BatchTokenizeSummary, inputDataType: DataType)
    case fileImported(fileName: String, totalValues: Int, validValues: Int, invalidValues: Int, dataType: DataType, sampleValues: [String])
    case error(String, String)
    case cacheCleared
    
    var id: String {
        UUID().uuidString
    }
    
    var timestamp: Date {
        Date()
    }
    
    var title: String {
        switch self {
        case .loading:
            return "⏳ Loading"
        case .singleTokenize(_, _, _, _, _, let inputType):
            return "\(inputType.icon) Single Tokenize (\(inputType.displayName))"
        case .batchTokenize(_, _, let inputType):
            return "\(inputType.icon) Batch Tokenize (\(inputType.displayName))"
        case .fileImported:
            return "📂 File Imported"
        case .error(let title, _):
            return "❌ \(title)"
        case .cacheCleared:
            return "🗑️ Cache Cleared"
        }
    }
    
    var content: String {
        switch self {
        case .loading(let message):
            return message
            
        case .singleTokenize(let originalValue, let token, let exists, _, let dataType, let inputType):
            return """
            Input: \(originalValue)
            Token: \(token)
            Status: \(exists ? "Existing" : "New")
            Data Type: \(dataType)
            Input Type: \(inputType.displayName)
            """
            
        case .batchTokenize(let results, let summary, let inputType):
            var text = "Summary:\n"
            text += "• Processed: \(summary.processedCount)\n"
            text += "• Existing: \(summary.existingCount)\n"
            text += "• New: \(summary.newlyCreatedCount)\n"
            text += "• Input Type: \(inputType.displayName)\n"
            text += "\nResults:\n"
            for result in results {
                text += "• \(result.originalValue) → \(result.token)\n"
            }
            return text
            
        case .fileImported(let fileName, let totalValues, let validValues, let invalidValues, let dataType, let sampleValues):
            var text = "File: \(fileName)\n"
            text += "Data Type: \(dataType.displayName)\n"
            text += "Total Values: \(totalValues)\n"
            text += "✅ Valid: \(validValues)\n"
            if invalidValues > 0 {
                text += "❌ Invalid: \(invalidValues)\n"
            }
            let successRate = Int((Float(validValues) / Float(totalValues)) * 100)
            text += "Success Rate: \(successRate)%\n\n"
            text += "Sample Values:\n"
            for sample in sampleValues {
                text += "• \(sample)\n"
            }
            if validValues > sampleValues.count {
                text += "... and \(validValues - sampleValues.count) more"
            }
            return text

        case .error(_, let message):
            return message

        case .cacheCleared:
            return "Token cache has been cleared successfully"
        }
    }
    
    var detailedContent: String {
        switch self {
        case .batchTokenize(let results, let summary, let inputType):
            let successRate = results.isEmpty ? 0 : Int((Float(summary.processedCount) / Float(results.count)) * 100)

            var text = "📊 Batch Tokenize Results\n\n"
            text += "🎯 Data Type: \(inputType.displayName)\n\n"
            text += "📈 Statistics:\n"
            text += "• Total Items: \(results.count)\n"
            text += "• Processed: \(summary.processedCount)\n"
            text += "• Existing Tokens: \(summary.existingCount)\n"
            text += "• New Tokens: \(summary.newlyCreatedCount)\n"
            text += "• Success Rate: \(successRate)%\n\n"
            text += "🔍 Results:\n"
            for result in results.prefix(5) {
                text += "• \(result.originalValue) → \(result.token)\n"
            }
            if results.count > 5 {
                text += "\n... and \(results.count - 5) more"
            }
            return text
            
        case .fileImported(let fileName, let totalValues, let validValues, let invalidValues, let dataType, let sampleValues):
            let successRate = Int((Float(validValues) / Float(totalValues)) * 100)
            let errorRate = Int((Float(invalidValues) / Float(totalValues)) * 100)

            var text = "📂 File Import Summary\n\n"
            text += "📄 File: \(fileName)\n"
            text += "🎯 Target Type: \(dataType.displayName)\n"
            text += "⏰ Imported: \(timestamp.formatted(date: .omitted, time: .shortened))\n\n"
            text += "📊 Validation Results:\n"
            text += "• Total Values: \(totalValues)\n"
            text += "• ✅ Valid: \(validValues) (\(successRate)%)\n"
            text += "• ❌ Invalid: \(invalidValues) (\(errorRate)%)\n\n"
            text += "🔍 Sample Valid Values:\n"
            for sample in sampleValues {
                text += "• \(sample)\n"
            }
            if validValues > sampleValues.count {
                text += "\n... and \(validValues - sampleValues.count) more"
            }
            text += "\n\n💡 Ready for batch tokenization!"
            return text

        case .error(let title, let message):
            var text = "❌ Error Details\n\n"
            text += "🏷️ Type: \(title)\n"
            text += "⏰ Time: \(timestamp.formatted(date: .omitted, time: .complete))\n\n"
            text += "📝 Message:\n\(message)\n\n"
            text += "💡 Troubleshooting:\n"
            text += "• Check network connection\n"
            text += "• Verify API credentials\n"
            text += "• Ensure data format is correct\n"
            text += "• Try refreshing the token"
            return text
            
        default:
            return content
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .loading:
            return Color.yellow.opacity(0.2)
        case .singleTokenize:
            return Color.green.opacity(0.2)
        case .batchTokenize:
            return Color.purple.opacity(0.2)
        case .fileImported:
            return Color.blue.opacity(0.2)
        case .error:
            return Color.red.opacity(0.2)
        case .cacheCleared:
            return Color.orange.opacity(0.2)
        }
    }
    
    var isExpandable: Bool {
        switch self {
        case .batchTokenize, .fileImported, .error:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sample Data Provider
struct SampleDataProvider {
    // String samples - PII examples
    private static let sampleStrings = [
        "555-12-3456",              // SSN
        "john.doe@example.com",     // Email
        "4111-2222-3333-4444",      // Credit Card
        "jane.smith@test.com",      // Email
        "987-65-4321",              // SSN
        "+1-555-123-4567",          // Phone
        "alice.johnson@demo.org",   // Email
        "123-45-6789",              // SSN
        "5555-4444-3333-2222",      // Credit Card
        "bob.wilson@sample.net",    // Email
        "+44-20-7946-0958",         // UK Phone
        "111-22-3333",              // SSN
        "michael.brown@example.co.uk", // Email
        "6011-1111-1111-1117",      // Discover Card
        "+91-9876543210"            // Indian Phone
    ]
    
    // Int samples
    private static let sampleInts = [
        123456, 987654, 555123, 789456, 111222,
        333444, 567890, 246813, 135792, 864209,
        999888, 777666, 444555, 888999, 123321
    ]
    
    // Long samples
    private static let sampleLongs: [Int64] = [
        9876543210, 1234567890, 5555666677, 9999888877, 1111222233,
        7777666655, 4444333322, 8888999900, 2222111100, 6666777788,
        3333444455, 5555444433, 9999000011, 1111333355, 7777888899
    ]
    
    // Float samples
    private static let sampleFloats: [Float] = [
        123.45, 987.65, 555.12, 789.33, 111.22,
        333.44, 567.89, 246.81, 135.79, 864.20,
        999.88, 777.66, 444.55, 888.99, 123.32
    ]
    
    // Double samples
    private static let sampleDoubles = [
        123.456789, 987.654321, 555.123456, 789.987654, 111.222333,
        333.444555, 567.890123, 246.813579, 135.792468, 864.209753,
        999.888777, 777.666555, 444.555666, 888.999000, 123.321123
    ]
    
    // Boolean samples
    private static let sampleBooleans = [
        true, false, true, true, false,
        false, true, false, true, false,
        true, true, false, false, true
    ]
    
    static func getRandomSample(for type: DataType) -> String {
        switch type {
        case .string:
            return sampleStrings.randomElement() ?? ""
        case .int:
            return String(sampleInts.randomElement() ?? 0)
        case .long:
            return String(sampleLongs.randomElement() ?? 0)
        case .float:
            return String(sampleFloats.randomElement() ?? 0.0)
        case .double:
            return String(sampleDoubles.randomElement() ?? 0.0)
        case .boolean:
            return String(sampleBooleans.randomElement() ?? false)
        }
    }
    
    static func getBatchSample(for type: DataType) -> [Any] {
        let batchSize = Int.random(in: 3...7)
        
        switch type {
        case .string:
            return Array(sampleStrings.shuffled().prefix(batchSize))
        case .int:
            return Array(sampleInts.shuffled().prefix(batchSize))
        case .long:
            return Array(sampleLongs.shuffled().prefix(batchSize))
        case .float:
            return Array(sampleFloats.shuffled().prefix(batchSize))
        case .double:
            return Array(sampleDoubles.shuffled().prefix(batchSize))
        case .boolean:
            return Array(sampleBooleans.shuffled().prefix(batchSize))
        }
    }
}

