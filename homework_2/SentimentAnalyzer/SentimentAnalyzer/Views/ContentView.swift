//
//  ContentView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var analysisViewModel: AnalysisViewModel
    @StateObject private var contentViewModel: ContentViewModel
    @StateObject private var realTimeViewModel: RealTimeAnalysisViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @State private var showingDetails = false
    @State private var showingHistory = false
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @FocusState private var isInputFocused: Bool

    init(
        analysisViewModel: @autoclosure @escaping () -> AnalysisViewModel,
        contentViewModel: @autoclosure @escaping () -> ContentViewModel,
        realTimeViewModel: @autoclosure @escaping () -> RealTimeAnalysisViewModel,
        historyViewModel: @autoclosure @escaping () -> HistoryViewModel
    ) {
        _analysisViewModel = StateObject(wrappedValue: analysisViewModel())
        _contentViewModel = StateObject(wrappedValue: contentViewModel())
        _realTimeViewModel = StateObject(wrappedValue: realTimeViewModel())
        _historyViewModel = StateObject(wrappedValue: historyViewModel())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TextEditorView(
                        text: $contentViewModel.inputText,
                        isFocused: $isInputFocused
                    )

                    HStack(spacing: 12) {
                        Button(action: { showingScanner = true }) {
                            Label("Сканер", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { showingPhotoPicker = true }) {
                            Label("Галерея", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    RealTimeAnalysisView(
                        text: $contentViewModel.inputText,
                        viewModel: realTimeViewModel
                    )

                    AnalysisButton(
                        viewModel: analysisViewModel,
                        text: contentViewModel.inputText,
                        isBlockedByFilter: realTimeViewModel.isBlockedByToxicityFilter
                    )

                    AnalysisResultsView(viewModel: analysisViewModel)

                    if let result = analysisViewModel.result {
                        ExportButtonsView(
                            onExportText: { contentViewModel.prepareTextExport(from: result) },
                            onExportPDF: { contentViewModel.preparePDFExport(from: result) }
                        )
                    }

                    TestCasesView(
                        viewModel: analysisViewModel,
                        inputText: $contentViewModel.inputText
                    )

                    Button("Запустить автотесты") {
                        contentViewModel.runAutoTests { text in
                            analysisViewModel.analyzeText(text)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    AnalysisDetailsView(viewModel: analysisViewModel, isExpanded: $showingDetails)
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Анализатор тональности")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: showingDetails ? "info.circle.fill" : "info.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            PhotoImportView(importedText: $contentViewModel.inputText, isPresented: $showingScanner)
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(importedText: $contentViewModel.inputText, isPresented: $showingPhotoPicker)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationView {
                HistoryView(viewModel: historyViewModel)
                    .navigationTitle("История анализов")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Готово") { showingHistory = false }
                        }
                    }
            }
        }
        .fileExporter(
            isPresented: $contentViewModel.isExporting,
            document: contentViewModel.exportDocument,
            contentType: contentViewModel.exportDocument?.contentType ?? .plainText,
            defaultFilename: contentViewModel.exportFileName
        ) { _ in
            contentViewModel.finishExport()
        }
        .onAppear {
            contentViewModel.consumeSharedTextIfNeeded { text in
                analysisViewModel.analyzeText(text)
            }
        }
        .onChange(of: appState.quickAction) { action in
            guard let action else { return }
            switch action {
            case .newAnalysis:
                contentViewModel.inputText = ""
                analysisViewModel.clearResults()
            case .openHistory:
                showingHistory = true
            }
            appState.quickAction = nil
        }
    }
}
