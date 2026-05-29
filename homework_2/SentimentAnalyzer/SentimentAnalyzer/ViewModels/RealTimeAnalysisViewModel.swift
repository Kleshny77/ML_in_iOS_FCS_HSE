//
//  RealTimeAnalysisViewModel.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RealTimeAnalysisViewModel: ObservableObject {
    @Published var quickSentiment: Sentiment?
    @Published var toxicityScore = 0.0
    @Published var toxicityFilterEnabled = false

    private let quickAnalyzer: QuickTextAnalyzing
    private var pendingTask: Task<Void, Never>?

    init(quickAnalyzer: QuickTextAnalyzing = KeywordQuickAnalysisService()) {
        self.quickAnalyzer = quickAnalyzer
    }

    var isBlockedByToxicityFilter: Bool {
        toxicityFilterEnabled && toxicityScore >= 0.5
    }

    var toxicityColor: Color {
        switch toxicityScore {
        case 0.65...:
            return .red
        case 0.35..<0.65:
            return .orange
        default:
            return .green
        }
    }

    func scheduleAnalysis(for text: String) {
        pendingTask?.cancel()

        pendingTask = Task { [quickAnalyzer] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }

            let snapshot = quickAnalyzer.analyzeQuick(text)
            await MainActor.run {
                self.quickSentiment = snapshot.sentiment
                self.toxicityScore = snapshot.toxicityScore
            }
        }
    }

    func cancelPendingAnalysis() {
        pendingTask?.cancel()
    }
}
