//
//  AnalysisButton.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

struct AnalysisButton: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let text: String
    let isBlockedByFilter: Bool

    var body: some View {
        Button(action: {
            viewModel.analyzeText(text)
        }) {
            HStack {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "text.magnifyingglass")
                }

                Text(viewModel.isAnalyzing ? "Анализ..." : "Анализировать тональность")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAnalyzing || isBlockedByFilter)
        .opacity((text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBlockedByFilter) ? 0.6 : 1)
    }
}
