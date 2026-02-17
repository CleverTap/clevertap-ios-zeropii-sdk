//
//  ZeroPIISampleApp.swift
//  ZeroPIISample
//
//  Created by Nishant Kumar on 05/02/26.
//

import SwiftUI
internal import UniformTypeIdentifiers
import clevertap_ios_vault_sdk

@main
struct ZeroPIISampleApp: App {
    init() {
        VaultSDK.initialize(clientId: "navin-client",
                            clientSecret: "83EpGODDbeyepKaGRy1Srg4c4YVEFQG8",
                            apiUrl: "https://vault.mangaforyou.com/ct-vault/",
                            authUrl: "https://auth-test.clevertap.net/auth/realms/master/",
                            logLevel: .debug)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var viewModel = ZeroPIIViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Header
                StatusHeaderView(viewModel: viewModel)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Data Type Selection
                        DataTypeSelectionView(selectedDataType: $viewModel.selectedDataType)
                        
                        // Operation Type Selection
                        OperationTypeSelectionView(selectedOperation: $viewModel.selectedOperation)
                        
                        // Input Section
                        InputSectionView(viewModel: viewModel)

                        // File Import Section (Batch only)
                        if viewModel.selectedOperation == .batch {
                            FileImportSectionView(viewModel: viewModel)
                        }

                        // Action Buttons
                        ActionButtonsView(viewModel: viewModel)
                        
                        // Utility Buttons
                        UtilityButtonsView(viewModel: viewModel)
                        
                        // Results List
                        ResultsListView(viewModel: viewModel)
                    }
                    .padding()
                }
            }
            .navigationTitle("ZeroPII SDK Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Status Header
struct StatusHeaderView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Encryption: ON", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("Cache: ON", systemImage: "externaldrive.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text("SDK Status: Ready")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Data Type Selection
struct DataTypeSelectionView: View {
    @Binding var selectedDataType: DataType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Type")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DataType.allCases, id: \.self) { type in
                        Button {
                            selectedDataType = type
                        } label: {
                            HStack {
                                Text(type.icon)
                                Text(type.displayName)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedDataType == type ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedDataType == type ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Operation Type Selection
struct OperationTypeSelectionView: View {
    @Binding var selectedOperation: OperationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operation Type")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(OperationType.allCases, id: \.self) { type in
                    Button {
                        selectedOperation = type
                    } label: {
                        Text(type.displayName)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedOperation == type ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedOperation == type ? .white : .primary)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

// MARK: - Input Section
struct InputSectionView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input")
                .font(.headline)

            if viewModel.selectedOperation == .single {
                TextField(viewModel.inputPlaceholder, text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                ForEach(viewModel.batchInputValues.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        TextField(viewModel.inputPlaceholder, text: $viewModel.batchInputValues[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if viewModel.batchInputValues.count > 1 {
                            Button {
                                viewModel.removeBatchInputField(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Button {
                    viewModel.addBatchInputField()
                } label: {
                    Label("Add Value", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - File Import Section
struct FileImportSectionView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel
    @State private var showingFilePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Or Import from File")
                .font(.headline)

            if let importStatus = viewModel.importStatus {
                HStack {
                    Text(importStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear") {
                        viewModel.clearImportedData()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            Button {
                showingFilePicker = true
            } label: {
                Label("Import File", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleFileImport(result)
            }
        }
    }
}

// MARK: - Action Buttons
struct ActionButtonsView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.selectedOperation == .single {
                // Single operation buttons
                Button {
                    viewModel.tokenizeSingleValue()
                } label: {
                    Label("Tokenize", systemImage: "lock.shield")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    viewModel.detokenizeSingleValue()
                } label: {
                    Label("Detokenize", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                // Batch operation buttons
                Button {
                    viewModel.batchTokenize()
                } label: {
                    Label("Batch Tokenize", systemImage: "lock.shield.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    viewModel.batchDetokenize()
                } label: {
                    Label("Batch Detokenize", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Utility Buttons
struct UtilityButtonsView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.clearCache()
            } label: {
                Label("Clear Cache", systemImage: "trash")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Button {
                viewModel.clearResults()
            } label: {
                Label("Clear Results", systemImage: "xmark.circle")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Results List
struct ResultsListView: View {
    @ObservedObject var viewModel: ZeroPIIViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.results.isEmpty {
                Text("Results")
                    .font(.headline)
                
                ForEach(viewModel.results) { result in
                    ResultItemView(item: result)
                }
            }
        }
    }
}

// MARK: - Result Item View
struct ResultItemView: View {
    let item: TokenDisplayItem
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(item.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(item.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(5)
            
            if item.isExpandable {
                Button {
                    showingDetails = true
                } label: {
                    Text("View Details")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(item.backgroundColor)
        .cornerRadius(10)
        .sheet(isPresented: $showingDetails) {
            ResultDetailView(item: item)
        }
    }
}

// MARK: - Result Detail View
struct ResultDetailView: View {
    let item: TokenDisplayItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.detailedContent)
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIPasteboard.general.string = item.detailedContent
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
