//
//  RealTimeAnalysisView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import SwiftUI

struct RealTimeAnalysisView: View {
    @Binding var text: String
    @ObservedObject var viewModel: RealTimeAnalysisViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Анализ в реальном времени")
                .font(.headline)

            if let sentiment = viewModel.quickSentiment, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 8) {
                    Text(sentiment.emoji)
                    Text(sentiment.rawValue)
                        .fontWeight(.semibold)
                        .foregroundColor(sentiment.color)
                }
            } else {
                Text("Введите текст для быстрого анализа")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Токсичность")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.toxicityScore * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.toxicityScore >= 0.5 ? .orange : .secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                        Capsule()
                            .fill(viewModel.toxicityColor)
                            .frame(width: geometry.size.width * CGFloat(viewModel.toxicityScore))
                    }
                }
                .frame(height: 8)
            }

            Toggle("Фильтр токсичного текста", isOn: $viewModel.toxicityFilterEnabled)
                .font(.subheadline)

            if viewModel.isBlockedByToxicityFilter {
                Text("Анализ кнопкой заблокирован: снизьте токсичность текста.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            viewModel.scheduleAnalysis(for: text)
        }
        .onChange(of: text) { newValue in
            viewModel.scheduleAnalysis(for: newValue)
        }
        .onDisappear {
            viewModel.cancelPendingAnalysis()
        }
    }
}
