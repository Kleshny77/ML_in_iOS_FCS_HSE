//
//  HistoryView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        Group {
            if viewModel.isEmpty {
                VStack(spacing: 16) {
                    StatisticsView(
                        stats: viewModel.sentimentStats,
                        emotionStats: viewModel.emotionStats,
                        dailyStats: viewModel.dailyStats
                    )

                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("История пуста")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    Section {
                        StatisticsView(
                            stats: viewModel.sentimentStats,
                            emotionStats: viewModel.emotionStats,
                            dailyStats: viewModel.dailyStats
                        )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(viewModel.history, id: \.timestamp) { result in
                            HistoryRow(result: result)
                        }
                        .onDelete(perform: viewModel.deleteItems)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.loadHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            viewModel.loadHistory()
        }
    }
}

private struct HistoryRow: View {
    let result: TextAnalysisResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.text.prefix(50) + (result.text.count > 50 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)

                HStack {
                    Text(result.sentiment.rawValue)
                        .font(.caption)
                        .foregroundColor(result.sentiment.color)

                    Text(result.sentiment.emoji)

                    if let emotion = result.emotion {
                        Text(emotion.emoji)
                    }

                    if let toxicity = result.toxicityScore {
                        Text("☣︎ \(Int(toxicity * 100))%")
                            .font(.caption2)
                            .foregroundColor(toxicity >= 0.5 ? .orange : .secondary)
                    }

                    Spacer()

                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
