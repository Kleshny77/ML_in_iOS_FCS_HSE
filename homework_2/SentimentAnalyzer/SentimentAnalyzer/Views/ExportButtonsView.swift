//
//  ExportButtonsView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import SwiftUI

struct ExportButtonsView: View {
    let onExportText: () -> Void
    let onExportPDF: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Экспорт результата:")
                .font(.headline)

            HStack(spacing: 12) {
                Button(action: onExportText) {
                    Label("TXT", systemImage: "doc.plaintext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onExportPDF) {
                    Label("PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
