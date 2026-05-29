//
//  SentimentSummaryWidget.swift
//  SentimentWidgetExtension
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import WidgetKit
import SwiftUI

private enum WidgetSharedStore {
    static let appGroupID = "group.com.example.SentimentAnalyzer"
    static let historyKey = "analysisHistory"
}

private struct WidgetResult: Codable {
    let sentiment: String
    let toxicityScore: Double?
    let timestamp: Date
}

private struct SentimentWidgetEntry: TimelineEntry {
    let date: Date
    let total: Int
    let positive: Int
    let neutral: Int
    let negative: Int
    let averageToxicity: Double
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SentimentWidgetEntry {
        SentimentWidgetEntry(
            date: Date(),
            total: 12,
            positive: 6,
            neutral: 3,
            negative: 3,
            averageToxicity: 0.18
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SentimentWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SentimentWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> SentimentWidgetEntry {
        let defaults = UserDefaults(suiteName: WidgetSharedStore.appGroupID)
        guard
            let data = defaults?.data(forKey: WidgetSharedStore.historyKey),
            let decoded = try? JSONDecoder().decode([WidgetResult].self, from: data)
        else {
            return SentimentWidgetEntry(
                date: Date(),
                total: 0,
                positive: 0,
                neutral: 0,
                negative: 0,
                averageToxicity: 0
            )
        }

        let recent = Array(decoded.prefix(30))
        let positive = recent.filter { $0.sentiment == "Позитивный" }.count
        let neutral = recent.filter { $0.sentiment == "Нейтральный" }.count
        let negative = recent.filter { $0.sentiment == "Негативный" }.count
        let toxicitySum = recent.reduce(0.0) { $0 + ($1.toxicityScore ?? 0.0) }
        let avgToxicity = recent.isEmpty ? 0.0 : toxicitySum / Double(recent.count)

        return SentimentWidgetEntry(
            date: Date(),
            total: recent.count,
            positive: positive,
            neutral: neutral,
            negative: negative,
            averageToxicity: avgToxicity
        )
    }
}

private struct SentimentSummaryWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тональность")
                .font(.headline)

            HStack(spacing: 12) {
                stat("😊", entry.positive)
                stat("😐", entry.neutral)
                stat("😠", entry.negative)
            }

            Text("Всего: \(entry.total)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Средняя токсичность: \(Int(entry.averageToxicity * 100))%")
                .font(.caption2)
                .foregroundColor(entry.averageToxicity >= 0.5 ? .orange : .secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func stat(_ emoji: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(emoji)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct SentimentSummaryWidget: Widget {
    let kind: String = "SentimentSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SentimentSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Тональность текста")
        .description("Краткая сводка последних анализов.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SentimentWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentimentSummaryWidget()
    }
}
