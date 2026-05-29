//
//  StatisticsView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import SwiftUI
import Charts

struct SentimentStat: Identifiable {
    let id: String
    let sentiment: Sentiment
    let count: Int
}

struct EmotionStat: Identifiable {
    let id: String
    let emotion: Emotion
    let count: Int
}

struct DailyAnalysisStat: Identifiable {
    let id: String
    let date: Date
    let count: Int
    let avgToxicity: Double
}

struct StatisticsView: View {
    let stats: [SentimentStat]
    let emotionStats: [EmotionStat]
    let dailyStats: [DailyAnalysisStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика по тональности")
                .font(.headline)

            Chart(stats) { item in
                BarMark(
                    x: .value("Тональность", item.sentiment.rawValue),
                    y: .value("Кол-во", item.count)
                )
                .foregroundStyle(item.sentiment.color)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 180)

            if !emotionStats.isEmpty {
                Text("Эмоции")
                    .font(.headline)

                Chart(emotionStats) { item in
                    BarMark(
                        x: .value("Эмоция", item.emotion.rawValue),
                        y: .value("Кол-во", item.count)
                    )
                    .foregroundStyle(item.emotion.color)
                }
                .frame(height: 140)
            }

            if !dailyStats.isEmpty {
                Text("Активность по времени")
                    .font(.headline)

                Chart(dailyStats) { item in
                    LineMark(
                        x: .value("Дата", item.date, unit: .day),
                        y: .value("Анализов", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Дата", item.date, unit: .day),
                        y: .value("Анализов", item.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue.opacity(0.15))
                }
                .frame(height: 150)

                Chart(dailyStats) { item in
                    BarMark(
                        x: .value("Дата", item.date, unit: .day),
                        y: .value("Токсичность", Int(item.avgToxicity * 100))
                    )
                    .foregroundStyle(item.avgToxicity >= 0.5 ? .orange : .green)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
