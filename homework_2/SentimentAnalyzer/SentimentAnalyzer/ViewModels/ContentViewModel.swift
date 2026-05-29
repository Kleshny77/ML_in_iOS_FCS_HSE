//
//  ContentViewModel.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var inputText = "Я очень доволен этим продуктом! Работает отлично."
    @Published var isExporting = false
    @Published var exportDocument: AnalysisExportDocument?
    @Published var exportFileName = "analysis"

    private let exportService: AnalysisExporting
    private let sharedTextConsumer: SharedTextConsuming

    init(
        exportService: AnalysisExporting = AnalysisExportServiceAdapter(),
        sharedTextConsumer: SharedTextConsuming = SharedTextInboxService()
    ) {
        self.exportService = exportService
        self.sharedTextConsumer = sharedTextConsumer
    }

    func prepareTextExport(from result: TextAnalysisResult) {
        let text = exportService.makeText(from: result)
        exportDocument = AnalysisExportDocument(
            data: Data(text.utf8),
            contentType: .plainText
        )
        exportFileName = fileName(for: result, ext: "txt")
        isExporting = true
    }

    func preparePDFExport(from result: TextAnalysisResult) {
        let data = exportService.makePDFData(from: result)
        exportDocument = AnalysisExportDocument(
            data: data,
            contentType: .pdf
        )
        exportFileName = fileName(for: result, ext: "pdf")
        isExporting = true
    }

    func finishExport() {
        isExporting = false
    }

    func consumeSharedTextIfNeeded(onReceived: (String) -> Void) {
        guard let sharedText = sharedTextConsumer.consumeSharedText() else { return }
        inputText = sharedText
        onReceived(sharedText)
    }

    func runAutoTests(onAnalyze: @escaping (String) -> Void) {
        let testTexts = [
            "Это отличный день! Я счастлив.",
            "Все ужасно, ничего не работает.",
            "Сегодня обычный день, ничего особенного.",
            "Ты дурак, иди отсюда!"
        ]

        for (index, text) in testTexts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2) { [weak self] in
                guard let self else { return }
                self.inputText = text
                onAnalyze(text)
            }
        }
    }
}

private extension ContentViewModel {
    func fileName(for result: TextAnalysisResult, ext: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let date = formatter.string(from: result.timestamp)
        return "sentiment_\(date).\(ext)"
    }
}
