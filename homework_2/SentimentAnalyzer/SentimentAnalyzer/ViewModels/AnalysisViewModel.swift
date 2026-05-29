//
//  AnalysisViewModel.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import Foundation
import Combine

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var result: TextAnalysisResult?
    @Published var isAnalyzing = false
    @Published var analysisDetails: [TextAnalysisResult.AnalysisDetail] = []
    @Published var errorMessage: String?

    private let analyzer: SentimentAnalyzing
    private let historyStore: AnalysisHistoryStoring

    init(
        analyzer: SentimentAnalyzing = SentimentAnalysisService(),
        historyStore: AnalysisHistoryStoring = SharedUserDefaultsHistoryStore()
    ) {
        self.analyzer = analyzer
        self.historyStore = historyStore
    }
    
    func analyzeText(_ text: String) {
        guard !text.isEmpty, !isAnalyzing else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await analyzer.analyze(text)
                self.result = result
                self.analysisDetails = result.details
                self.appendToHistory(result)
            } catch {
                self.errorMessage = "Ошибка анализа: \(error.localizedDescription)"
            }
            
            self.isAnalyzing = false
        }
    }
    
    func clearResults() {
        result = nil
        analysisDetails = []
        errorMessage = nil
    }

    private func appendToHistory(_ result: TextAnalysisResult) {
        var history = historyStore.loadHistory()
        history.insert(result, at: 0)
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        historyStore.saveHistory(history)
    }
}
