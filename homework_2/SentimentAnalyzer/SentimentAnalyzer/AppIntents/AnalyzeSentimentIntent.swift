//
//  AnalyzeSentimentIntent.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import AppIntents
import Combine

struct AnalyzeSentimentIntent: AppIntent {
    static var title: LocalizedStringResource = "Анализ тональности"
    static var description = IntentDescription("Анализирует тональность текста и возвращает результат.")

    @Parameter(title: "Текст")
    var text: String

    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let service = SentimentAnalysisService()
        let result = try await service.analyze(text)
        let summary = "\(result.sentiment.rawValue) · \(Int(result.confidence * 100))%"
        return .result(value: summary)
    }
}

struct SentimentShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AnalyzeSentimentIntent(),
            phrases: [
                "Проанализировать тональность в \(.applicationName)",
                "Понять тональность текста в \(.applicationName)",
                "Анализ тональности в \(.applicationName)"
            ]
        )
    }
}
