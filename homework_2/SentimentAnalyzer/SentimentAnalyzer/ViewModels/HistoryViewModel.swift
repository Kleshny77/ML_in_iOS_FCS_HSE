//
//  HistoryViewModel.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var history: [TextAnalysisResult] = []

    private let historyStore: AnalysisHistoryStoring

    init(historyStore: AnalysisHistoryStoring = SharedUserDefaultsHistoryStore()) {
        self.historyStore = historyStore
    }

    var isEmpty: Bool {
        history.isEmpty
    }

    var sentimentStats: [SentimentStat] {
        let grouped = Dictionary(grouping: history, by: { $0.sentiment })
        return [
            SentimentStat(id: "positive", sentiment: .positive, count: grouped[.positive]?.count ?? 0),
            SentimentStat(id: "neutral", sentiment: .neutral, count: grouped[.neutral]?.count ?? 0),
            SentimentStat(id: "negative", sentiment: .negative, count: grouped[.negative]?.count ?? 0)
        ]
    }

    var emotionStats: [EmotionStat] {
        let emotions = history.compactMap(\.emotion)
        return Dictionary(grouping: emotions, by: { $0 })
            .map { key, values in
                EmotionStat(id: key.rawValue, emotion: key, count: values.count)
            }
            .sorted { $0.count > $1.count }
    }

    var dailyStats: [DailyAnalysisStat] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: history) {
            calendar.startOfDay(for: $0.timestamp)
        }

        return buckets
            .map { day, results in
                let sum = results.reduce(0.0) { partial, result in
                    partial + (result.toxicityScore ?? toxicityFromDetails(result.details))
                }
                let avg = results.isEmpty ? 0.0 : sum / Double(results.count)
                return DailyAnalysisStat(
                    id: day.formatted(date: .numeric, time: .omitted),
                    date: day,
                    count: results.count,
                    avgToxicity: avg
                )
            }
            .sorted { $0.date < $1.date }
            .suffix(10)
            .map { $0 }
    }

    func loadHistory() {
        history = historyStore
            .loadHistory()
            .sorted { $0.timestamp > $1.timestamp }
    }

    func deleteItems(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            history.remove(at: index)
        }
        historyStore.saveHistory(history)
    }
}

private extension HistoryViewModel {
    func toxicityFromDetails(_ details: [TextAnalysisResult.AnalysisDetail]) -> Double {
        guard
            let text = details.first(where: { $0.title == "Токсичность" })?.value,
            let percent = Double(text.replacingOccurrences(of: "%", with: ""))
        else {
            return 0.0
        }
        return max(0.0, min(percent / 100.0, 1.0))
    }
}
