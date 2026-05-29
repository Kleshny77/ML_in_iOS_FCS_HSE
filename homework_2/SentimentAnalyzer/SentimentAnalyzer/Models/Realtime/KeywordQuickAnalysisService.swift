//
//  KeywordQuickAnalysisService.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation

final class KeywordQuickAnalysisService: QuickTextAnalyzing {
    func analyzeQuick(_ rawText: String) -> QuickAnalysisSnapshot {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else {
            return QuickAnalysisSnapshot(sentiment: nil, toxicityScore: 0.0)
        }

        let positiveWords = ["хорош", "отлич", "супер", "нрав", "доволен", "рад", "люблю"]
        let negativeWords = ["плохо", "ужас", "кошмар", "ненавиж", "сломал", "проблем", "отстой"]
        let toxicWords = ["идиот", "дурак", "тупой", "убей", "сдохни", "ненавижу"]

        let positiveHits = positiveWords.filter { text.contains($0) }.count
        let negativeHits = negativeWords.filter { text.contains($0) }.count
        let score = positiveHits - negativeHits

        let sentiment: Sentiment
        if score > 0 {
            sentiment = .positive
        } else if score < 0 {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }

        let toxicHits = toxicWords.filter { text.contains($0) }.count
        let toxicityScore = min(Double(toxicHits) * 0.35, 1.0)

        return QuickAnalysisSnapshot(
            sentiment: sentiment,
            toxicityScore: toxicityScore
        )
    }
}
