//
//  SentimentComponent.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 27.02.2026.
//

import SwiftUI

struct SentimentComponent: SentimentComponentProtocol {
    let sentimentAnalyzer: SentimentAnalyzing
    let quickAnalyzer: QuickTextAnalyzing
    let historyStore: AnalysisHistoryStoring
    let exportService: AnalysisExporting
    let sharedTextConsumer: SharedTextConsuming

    init(
        sentimentAnalyzer: SentimentAnalyzing,
        quickAnalyzer: QuickTextAnalyzing,
        historyStore: AnalysisHistoryStoring,
        exportService: AnalysisExporting,
        sharedTextConsumer: SharedTextConsuming
    ) {
        self.sentimentAnalyzer = sentimentAnalyzer
        self.quickAnalyzer = quickAnalyzer
        self.historyStore = historyStore
        self.exportService = exportService
        self.sharedTextConsumer = sharedTextConsumer
    }

    @MainActor
    var view: some View {
        ContentView(
            analysisViewModel: makeAnalysisViewModel(),
            contentViewModel: makeContentViewModel(),
            realTimeViewModel: makeRealTimeViewModel(),
            historyViewModel: makeHistoryViewModel()
        )
    }
}

extension SentimentComponent {
    @MainActor
    func makeAnalysisViewModel() -> AnalysisViewModel {
        AnalysisViewModel(
            analyzer: sentimentAnalyzer,
            historyStore: historyStore
        )
    }

    @MainActor
    func makeContentViewModel() -> ContentViewModel {
        ContentViewModel(
            exportService: exportService,
            sharedTextConsumer: sharedTextConsumer
        )
    }

    @MainActor
    func makeRealTimeViewModel() -> RealTimeAnalysisViewModel {
        RealTimeAnalysisViewModel(quickAnalyzer: quickAnalyzer)
    }

    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(historyStore: historyStore)
    }
}
