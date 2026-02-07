//
//  ZeroPIIViewModel.swift
//  ZeroPIISample
//
//  Created by Nishant Kumar on 05/02/26.
//

import Foundation
import SwiftUI
import Combine
import clevertap_ios_vault_sdk

// MARK: - View Model
class ZeroPIIViewModel: ObservableObject {
    @Published var selectedDataType: DataType = .string
    @Published var selectedOperation: OperationType = .single
    @Published var inputText: String = ""
    @Published var results: [TokenDisplayItem] = []
    @Published var importStatus: String?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private var importedData: [Any] = []
    private var importedFileName: String?
//    private let zeroPIISDK = ZeroPIISDK.shared
    
    var inputPlaceholder: String {
        switch selectedDataType {
        case .string:
            return "Enter string value/Token (e.g., john@example.com)"
        case .int:
            return "Enter integer value (e.g., 123456)"
        case .long:
            return "Enter long value (e.g., 9876543210)"
        case .float:
            return "Enter float value (e.g., 123.45)"
        case .double:
            return "Enter double value (e.g., 123.456789)"
        case .boolean:
            return "Enter boolean value (true or false)"
        }
    }
    
    // MARK: - Sample Data
    func loadSampleData(for type: DataType) {
        inputText = SampleDataProvider.getRandomSample(for: type)
    }
    
    // MARK: - Single Operations
    func tokenizeSingleValue() {
        guard !inputText.isEmpty else {
            showErrorAlert("Please enter a value to tokenize")
            return
        }
        
        guard let value = parseInputValue(inputText) else {
            showErrorAlert("Invalid \(selectedDataType.displayName) format")
            return
        }
        
        addResult(.loading("Tokenizing \(inputText) as \(selectedDataType.displayName)..."))
        let zeroPIISDK = VaultSDK.getInstance()
        
        switch selectedDataType {
        case .string:
            let valueString = value as! String
            zeroPIISDK.tokenizeString(valueString) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueString, result: result)
            }
        case .int:
            let valueInt = value as! Int
            zeroPIISDK.tokenizeInt(valueInt) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueInt, result: result)
            }
        case .long:
            let valueLong = value as! Int64
            zeroPIISDK.tokenizeLong(valueLong) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueLong, result: result)
            }
        case .float:
            let valueFloat = value as! Float
            zeroPIISDK.tokenizeFloat(valueFloat) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueFloat, result: result)
            }
        case .double:
            let valueDouble = value as! Double
            zeroPIISDK.tokenizeDouble(valueDouble) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueDouble, result: result)
            }
        case .boolean:
            let valueBool = value as! Bool
            zeroPIISDK.tokenizeBool(valueBool) { [weak self] result in
                self?.handleTokenizeResult(originalValue: valueBool, result: result)
            }
        }
    }
    
    func detokenizeSingleValue() {
        guard !inputText.isEmpty else {
            showErrorAlert("Please enter a token to detokenize")
            return
        }
        
        addResult(.loading("Detokenizing \(inputText) as \(selectedDataType.displayName)..."))
        
//        switch selectedDataType {
//        case .string:
//            zeroPIISDK.detokenizeAsString(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        case .int:
//            zeroPIISDK.detokenizeAsInt(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        case .long:
//            zeroPIISDK.detokenizeAsLong(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        case .float:
//            zeroPIISDK.detokenizeAsFloat(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        case .double:
//            zeroPIISDK.detokenizeAsDouble(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        case .boolean:
//            zeroPIISDK.detokenizeAsBoolean(inputText) { [weak self] result in
//                self?.handleDetokenizeResult(token: self?.inputText ?? "", result: result)
//            }
//        }
    }
    
    // MARK: - Batch Operations
    func batchTokenize() {
        if !importedData.isEmpty {
            batchTokenizeImportedValues()
        } else {
            batchTokenizeSampleValues()
        }
    }
    
    func batchDetokenize() {
        if !importedData.isEmpty {
            batchDetokenizeImportedValues()
        } else {
            batchDetokenizeAvailableTokens()
        }
    }
    
    private func batchTokenizeSampleValues() {
        let sampleData = SampleDataProvider.getBatchSample(for: selectedDataType)
        
        addResult(.loading("Batch tokenizing \(sampleData.count) sample \(selectedDataType.displayName) values..."))
        
        performBatchTokenize(sampleData, isImported: false)
    }
    
    private func batchTokenizeImportedValues() {
        guard !importedData.isEmpty else {
            showErrorAlert("No imported data available")
            return
        }
        
        addResult(.loading("Batch tokenizing \(importedData.count) imported \(selectedDataType.displayName) values from \(importedFileName ?? "file")..."))
        
        performBatchTokenize(importedData, isImported: true)
    }
    
    private func performBatchTokenize(_ data: [Any], isImported: Bool) {
//        switch selectedDataType {
//        case .string:
//            zeroPIISDK.batchTokenizeStrings(data as! [String]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        case .int:
//            zeroPIISDK.batchTokenizeInts(data as! [Int]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        case .long:
//            zeroPIISDK.batchTokenizeLongs(data as! [Int64]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        case .float:
//            zeroPIISDK.batchTokenizeFloats(data as! [Float]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        case .double:
//            zeroPIISDK.batchTokenizeDoubles(data as! [Double]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        case .boolean:
//            zeroPIISDK.batchTokenizeBooleans(data as! [Bool]) { [weak self] result in
//                self?.handleBatchTokenizeResult(result, isImported: isImported)
//            }
//        }
    }
    
    private func batchDetokenizeImportedValues() {
        guard !importedData.isEmpty else {
            showErrorAlert("No imported data available")
            return
        }
        
        let tokens = importedData.map { String(describing: $0) }
        addResult(.loading("Batch detokenizing \(tokens.count) imported \(selectedDataType.displayName) tokens from \(importedFileName ?? "file")..."))
        
        performBatchDetokenize(tokens)
    }
    
    private func batchDetokenizeAvailableTokens() {
        let availableTokens = extractAvailableTokens()
        
        guard !availableTokens.isEmpty else {
            showErrorAlert("No \(selectedDataType.displayName) tokens available. Please tokenize some \(selectedDataType.displayName) values first.")
            return
        }
        
        addResult(.loading("Batch detokenizing \(availableTokens.count) \(selectedDataType.displayName) tokens..."))
        
        performBatchDetokenize(availableTokens)
    }
    
    private func performBatchDetokenize(_ tokens: [String]) {
//        switch selectedDataType {
//        case .string:
//            zeroPIISDK.batchDetokenizeAsStrings(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        case .int:
//            zeroPIISDK.batchDetokenizeAsInts(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        case .long:
//            zeroPIISDK.batchDetokenizeAsLongs(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        case .float:
//            zeroPIISDK.batchDetokenizeAsFloats(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        case .double:
//            zeroPIISDK.batchDetokenizeAsDoubles(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        case .boolean:
//            zeroPIISDK.batchDetokenizeAsBooleans(tokens) { [weak self] result in
//                self?.handleBatchDetokenizeResult(result)
//            }
//        }
    }
    
    // MARK: - File Import
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importDataFromFile(url)
        case .failure(let error):
            showErrorAlert("Failed to import file: \(error.localizedDescription)")
        }
    }
    
    private func importDataFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showErrorAlert("Failed to access file")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.lastPathComponent
            parseFileContent(content, fileName: fileName)
        } catch {
            showErrorAlert("Error reading file: \(error.localizedDescription)")
            addResult(.error("File Import Error", "Failed to read file: \(error.localizedDescription)"))
        }
    }
    
    private func parseFileContent(_ content: String, fileName: String) {
        // Parse comma or newline separated values
        let rawValues = content.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !rawValues.isEmpty else {
            showErrorAlert("No valid data found in file")
            return
        }
        
        // Validate and convert data
        let (validData, invalidCount) = validateAndConvert(rawValues)
        
        guard !validData.isEmpty else {
            showErrorAlert("No valid \(selectedDataType.displayName) values found in file")
            addResult(.error("File Import Error", "No valid \(selectedDataType.displayName) values found in file. Check data format."))
            return
        }
        
        // Store imported data
        importedData = validData
        importedFileName = fileName
        
        // Update status
        updateImportStatus(validCount: validData.count, invalidCount: invalidCount, fileName: fileName)
        
        // Add result
        let sampleValues = validData.prefix(3).map { String(describing: $0) }
        addResult(.fileImported(
            fileName: fileName,
            totalValues: rawValues.count,
            validValues: validData.count,
            invalidValues: invalidCount,
            dataType: selectedDataType,
            sampleValues: sampleValues
        ))
    }
    
    private func validateAndConvert(_ rawValues: [String]) -> ([Any], Int) {
        var validData: [Any] = []
        var invalidCount = 0
        
        for rawValue in rawValues {
            if let converted = parseInputValue(rawValue) {
                validData.append(converted)
            } else {
                invalidCount += 1
            }
        }
        
        return (validData, invalidCount)
    }
    
    private func updateImportStatus(validCount: Int, invalidCount: Int, fileName: String) {
        if invalidCount > 0 {
            importStatus = "📄 \(fileName): \(validCount) valid, \(invalidCount) invalid \(selectedDataType.displayName) values"
        } else {
            importStatus = "📄 \(fileName): \(validCount) valid \(selectedDataType.displayName) values"
        }
    }
    
    func clearImportedData() {
        importedData = []
        importedFileName = nil
        importStatus = nil
    }
    
    // MARK: - Utility
    func clearCache() {
//        zeroPIISDK.clearCache()
        addResult(.cacheCleared)
    }
    
    func clearResults() {
        results.removeAll()
    }
    
    // MARK: - Result Handlers
    private func handleTokenizeResult<T>(originalValue: T, result: TokenizeResult) {
        guard let token = result.token else {
            self.addResult(.error("\(self.selectedDataType.displayName) Tokenize Error", "Failed to tokenize \(self.selectedDataType.displayName) value"))
            return
        }
        let originalString = String(describing: originalValue)
        DispatchQueue.main.async {
            self.removeLastLoadingItem()
            self.addResult(.singleTokenize(
                originalValue: originalString,
                token: token,
                exists: result.exists,
                newlyCreated: result.newlyCreated,
                dataType: result.dataType ?? "unknown",
                inputDataType: self.selectedDataType
            ))
        }
    }
    
    private func handleDetokenizeResult<T>(token: String, result: DetokenizeResult<T>) {
        DispatchQueue.main.async {
            self.removeLastLoadingItem()
            
            switch result {
            case .success(let data):
                self.addResult(.singleDetokenize(
                    token: token,
                    originalValue: String(describing: data.value as? String ?? "null"),
                    exists: data.exists,
                    dataType: data.dataType ?? "unknown",
                    outputDataType: self.selectedDataType
                ))
            case .failure(let error):
                self.addResult(.error("\(self.selectedDataType.displayName) Detokenize Error", error.localizedDescription))
            }
        }
    }
    
    private func handleBatchTokenizeResult(_ result: BatchTokenizeResult, isImported: Bool) {
        DispatchQueue.main.async {
            self.removeLastLoadingItem()
            
            switch result {
            case .success(let data):
                self.addResult(.batchTokenize(
                    results: data.results,
                    summary: data.summary,
                    inputDataType: self.selectedDataType,
                    isImported: isImported,
                    fileName: isImported ? self.importedFileName : nil
                ))
            case .failure(let error):
                self.addResult(.error("\(self.selectedDataType.displayName) Batch Tokenize Error", error.localizedDescription))
            }
        }
    }
    
    private func handleBatchDetokenizeResult<T>(_ result: BatchDetokenizeResult<T>) {
        DispatchQueue.main.async {
            self.removeLastLoadingItem()
            
            switch result {
            case .success(let data):
                // Convert to string for display
                let stringResults = data.results.map { item in
                    BatchDetokenItem(
                        token: item.token,
                        value: item.value != nil ? String(describing: item.value!) : nil,
                        exists: item.exists,
                        dataType: item.dataType
                    )
                }
                
                self.addResult(.batchDetokenize(
                    results: stringResults,
                    summary: data.summary,
                    outputDataType: self.selectedDataType
                ))
            case .failure(let error):
                self.addResult(.error("\(self.selectedDataType.displayName) Batch Detokenize Error", error.localizedDescription))
            }
        }
    }
    
    // MARK: - Helpers
    private func parseInputValue(_ input: String) -> Any? {
        switch selectedDataType {
        case .string:
            return input
        case .int:
            return Int(input)
        case .long:
            return Int64(input)
        case .float:
            return Float(input)
        case .double:
            return Double(input)
        case .boolean:
            let lower = input.lowercased()
            if ["true", "1", "yes", "y"].contains(lower) {
                return true
            } else if ["false", "0", "no", "n"].contains(lower) {
                return false
            }
            return nil
        }
    }
    
    private func extractAvailableTokens() -> [String] {
        var tokens: [String] = []
        
        for result in results {
            switch result {
            case .singleTokenize(_, let token, _, _, let dataType, _):
                if isDataTypeCompatible(serverType: dataType) {
                    tokens.append(token)
                }
            case .batchTokenize(let items, _, _, _, _):
                tokens.append(contentsOf: items.filter { isDataTypeCompatible(serverType: $0.dataType) }.map { $0.token })
            default:
                break
            }
        }
        
        return Array(Set(tokens)) // Remove duplicates
    }
    
    private func isDataTypeCompatible(serverType: String?) -> Bool {
        guard let serverType = serverType?.lowercased() else { return false }
        
        switch selectedDataType {
        case .string:
            return ["string", "text"].contains(serverType)
        case .int:
            return ["number", "integer", "int"].contains(serverType)
        case .long:
            return ["number", "long", "bigint"].contains(serverType)
        case .float:
            return ["number", "float", "decimal"].contains(serverType)
        case .double:
            return ["number", "double", "decimal"].contains(serverType)
        case .boolean:
            return ["boolean", "bool", "string"].contains(serverType)
        }
    }
    
    private func addResult(_ item: TokenDisplayItem) {
        DispatchQueue.main.async {
            self.results.insert(item, at: 0)
        }
    }
    
    private func removeLastLoadingItem() {
        if let index = results.firstIndex(where: { if case .loading = $0 { return true } else { return false } }) {
            results.remove(at: index)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}
