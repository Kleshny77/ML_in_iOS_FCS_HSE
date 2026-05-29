//
//  AnalysisResultsView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//
import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isAnalyzing {
                ProgressView("Анализ текста...")
                    .padding()
            } else if let result = viewModel.result {
                SentimentCard(result: result)

                ConfidenceIndicator(confidence: result.confidence)

                SentimentVisualization(result: result)

                Text("Детали анализа:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let summaryDetails = summaryDetails(from: result.details)
                ForEach(summaryDetails, id: \.title) { detail in
                    AnalysisDetailRow(detail: detail)
                }
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

private func summaryDetails(
    from details: [TextAnalysisResult.AnalysisDetail]
) -> [TextAnalysisResult.AnalysisDetail] {
    var top = Array(details.prefix(3))
    if let alert = details.first(where: { $0.title.contains("⚠️") }) {
        if !top.contains(where: { $0.title == alert.title }) {
            top.append(alert)
        }
        return top
    }
    if !top.contains(where: { $0.type == .warning }),
       let warning = details.first(where: { $0.type == .warning }) {
        top.append(warning)
    }
    return top
}
struct SentimentCard: View {
    let result: TextAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Результат анализа")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(result.sentiment.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(result.sentiment.color)

                        Text(result.sentiment.emoji)
                            .font(.title2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Уверенность")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(Int(result.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }

            Text("Язык: \(result.language)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let emotion = result.emotion {
                Text("Эмоция: \(emotion.emoji) \(emotion.rawValue)")
                    .font(.caption)
                    .foregroundColor(emotion.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let toxicity = result.toxicityScore {
                Text("Токсичность: \(Int(toxicity * 100))%")
                    .font(.caption)
                    .foregroundColor(toxicity >= 0.5 ? .orange : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(result.sentiment.color.opacity(0.1))
        )
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Уверенность модели:")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая линия
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)

                    // Индикатор уверенности
                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence),
                               height: 8)
                        .cornerRadius(4)

                    // Текущая позиция
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * CGFloat(confidence) - 8)
                }
            }
            .frame(height: 20)

            HStack {
                Text("0%")
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .fontWeight(.semibold)
                Spacer()
                Text("100%")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .orange
        }
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
                .font(.title2)

            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}
