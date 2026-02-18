//
//  ZeroPIIViewModel.swift
//  ZeroPIISample
//
//  Created by Nishant Kumar on 05/02/26.
//

import Foundation
import SwiftUI
import Combine
import clevertap_ios_zeropii_sdk

// MARK: - View Model
class ZeroPIIViewModel: ObservableObject {
    @Published var selectedDataType: DataType = .string
    @Published var selectedOperation: OperationType = .single
    @Published var inputText: String = ""
    @Published var batchInputValues: [String] = [""]
    @Published var results: [TokenDisplayItem] = []
    @Published var importStatus: String?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private var importedData: [Any] = []
    private var importedFileName: String?
    
    var inputPlaceholder: String {
        switch selectedDataType {
        case .string:
            return "Enter string value (e.g., john@example.com)"
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
        let zeroPIISDK = ZeroPiiSDK.getInstance()
        
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
    
    // MARK: - Batch Input Management
    func addBatchInputField() {
        batchInputValues.append("")
    }

    func removeBatchInputField(at index: Int) {
        guard batchInputValues.count > 1 else { return }
        batchInputValues.remove(at: index)
    }

    // MARK: - Batch Operations
    func batchTokenize() {
        if !importedData.isEmpty {
            addResult(.loading("Batch tokenizing \(importedData.count) imported \(selectedDataType.displayName) values from \(importedFileName ?? "file")..."))
            performBatchTokenize(importedData)
        } else {
            let nonEmptyValues = batchInputValues.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard !nonEmptyValues.isEmpty else {
                showErrorAlert("Please add at least one value to batch tokenize")
                return
            }

            var parsedData: [Any] = []
            for value in nonEmptyValues {
                guard let parsed = parseInputValue(value) else {
                    showErrorAlert("Invalid \(selectedDataType.displayName) format: \(value)")
                    return
                }
                parsedData.append(parsed)
            }

            addResult(.loading("Batch tokenizing \(parsedData.count) \(selectedDataType.displayName) values..."))
            performBatchTokenize(parsedData)
        }
    }

    private func performBatchTokenize(_ data: [Any]) {
        let zeroPIISDK = ZeroPiiSDK.getInstance()
        switch selectedDataType {
        case .string:
            zeroPIISDK.batchTokenizeStringValues(data as! [String]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        case .int:
            zeroPIISDK.batchTokenizeIntValues(data as! [Int]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        case .long:
            zeroPIISDK.batchTokenizeLongValues(data as! [Int64]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        case .float:
            zeroPIISDK.batchTokenizeFloatValues(data as! [Float]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        case .double:
            zeroPIISDK.batchTokenizeDoubleValues(data as! [Double]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        case .boolean:
            zeroPIISDK.batchTokenizeBoolValues(data as! [Bool]) { [weak self] result in
                self?.handleBatchTokenizeResult(result)
            }
        }
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
        let rawValues = content.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !rawValues.isEmpty else {
            showErrorAlert("No valid data found in file")
            return
        }

        let (validData, invalidCount) = validateAndConvert(rawValues)

        guard !validData.isEmpty else {
            showErrorAlert("No valid \(selectedDataType.displayName) values found in file")
            addResult(.error("File Import Error", "No valid \(selectedDataType.displayName) values found in file. Check data format."))
            return
        }

        importedData = validData
        importedFileName = fileName

        if invalidCount > 0 {
            importStatus = "📄 \(fileName): \(validData.count) valid, \(invalidCount) invalid \(selectedDataType.displayName) values"
        } else {
            importStatus = "📄 \(fileName): \(validData.count) valid \(selectedDataType.displayName) values"
        }

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

    func clearImportedData() {
        importedData = []
        importedFileName = nil
        importStatus = nil
    }

    // MARK: - Utility
    func clearCache() {
        ZeroPiiSDK.getInstance().clearCache()
        addResult(.cacheCleared)
    }
    
    func clearResults() {
        results.removeAll()
    }
    
    // MARK: - Result Handlers
    private func handleTokenizeResult<T>(originalValue: T, result: TokenizeResult) {
        self.removeLastLoadingItem()

        guard let token = result.token else {
            self.addResult(.error("\(self.selectedDataType.displayName) Tokenize Error", "Failed to tokenize \(self.selectedDataType.displayName) value"))
            return
        }
        let originalString = String(describing: originalValue)

        self.addResult(.singleTokenize(
            originalValue: originalString,
            token: token,
            exists: result.exists,
            newlyCreated: result.newlyCreated,
            dataType: result.dataType ?? "unknown",
            inputDataType: self.selectedDataType
        ))
    }
    
    private func handleBatchTokenizeResult(_ result: BatchTokenizeResult) {
        DispatchQueue.main.async {
            self.removeLastLoadingItem()
            if result.isSuccess {
                self.addResult(.batchTokenize(
                    results: result.results,
                    summary: result.summary ?? BatchTokenizeSummary(processedCount: 0, existingCount: 0, newlyCreatedCount: 0),
                    inputDataType: self.selectedDataType
                ))
            } else {
                self.addResult(.error("\(self.selectedDataType.displayName) Batch Tokenize Error", "Batch tokenization failed. Check the console for more details."))
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
    
    private func addResult(_ item: TokenDisplayItem) {
        DispatchQueue.main.async {
            self.results.insert(item, at: 0)
        }
    }
    
    private func removeLastLoadingItem() {
        DispatchQueue.main.async { [weak self] in
            if let index = self?.results.firstIndex(where: { if case .loading = $0 { return true } else { return false } }) {
                self?.results.remove(at: index)
            }
        }
    }
    
    private func showErrorAlert(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}
