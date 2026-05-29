//
//  SentimentVisualization.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct SentimentVisualization: View {
    let result: TextAnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Шкала тональности:")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [.red, .yellow, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .cornerRadius(4)

                    Circle()
                        .fill(result.sentiment.color)
                        .frame(width: 14, height: 14)
                        .offset(x: indicatorX(in: geometry.size.width))
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
            }
            .frame(height: 18)

            HStack {
                Text("Негатив")
                Spacer()
                Text("Нейтрально")
                Spacer()
                Text("Позитив")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }

    private func indicatorX(in width: CGFloat) -> CGFloat {
        let normalized = (sentimentScore + 1) / 2
        let clamped = min(max(normalized, 0), 1)
        return width * CGFloat(clamped) - 7
    }

    private var sentimentScore: Double {
        switch result.sentiment {
        case .positive:
            return min(result.confidence, 1.0)
        case .negative:
            return -min(result.confidence, 1.0)
        case .neutral:
            return 0.0
        }
    }
}
