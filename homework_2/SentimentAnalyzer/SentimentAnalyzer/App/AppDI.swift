//
//  AppDI.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 27.02.2026.
//

import Foundation

final class AppDI {
    static let shared = AppDI()

    private init() {}

    lazy var sentimentAnalyzer: SentimentAnalyzing = {
        SentimentAnalysisService()
    }()

    lazy var quickAnalyzer: QuickTextAnalyzing = {
        KeywordQuickAnalysisService()
    }()

    lazy var historyStore: AnalysisHistoryStoring = {
        SharedUserDefaultsHistoryStore()
    }()

    lazy var exportService: AnalysisExporting = {
        AnalysisExportServiceAdapter()
    }()

    lazy var sharedTextConsumer: SharedTextConsuming = {
        SharedTextInboxService()
    }()
}
