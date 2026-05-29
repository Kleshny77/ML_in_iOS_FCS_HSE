//
//  ServiceProtocols.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 27.02.2026.
//

import Foundation

protocol SentimentAnalyzing {
    func analyze(_ text: String) async throws -> TextAnalysisResult
}

struct QuickAnalysisSnapshot {
    let sentiment: Sentiment?
    let toxicityScore: Double
}

protocol QuickTextAnalyzing {
    func analyzeQuick(_ text: String) -> QuickAnalysisSnapshot
}

protocol AnalysisHistoryStoring {
    func loadHistory() -> [TextAnalysisResult]
    func saveHistory(_ history: [TextAnalysisResult])
}

protocol AnalysisExporting {
    func makeText(from result: TextAnalysisResult) -> String
    func makePDFData(from result: TextAnalysisResult) -> Data
}

protocol SharedTextConsuming {
    func consumeSharedText() -> String?
}

final class AnalysisExportServiceAdapter: AnalysisExporting {
    func makeText(from result: TextAnalysisResult) -> String {
        AnalysisExportService.makeText(from: result)
    }

    func makePDFData(from result: TextAnalysisResult) -> Data {
        AnalysisExportService.makePDFData(from: result)
    }
}
