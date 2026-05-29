//
//  TextEditorView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct TextEditorView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Введите текст для анализа:")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(height: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDropTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .onDrop(of: [.plainText], isTargeted: $isDropTargeted) { providers in
                        guard let provider = providers.first else { return false }
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                            DispatchQueue.main.async {
                                if let data = item as? Data,
                                   let string = String(data: data, encoding: .utf8) {
                                    text = string
                                } else if let string = item as? String {
                                    text = string
                                }
                            }
                        }
                        return true
                    }

                if text.isEmpty {
                    Text("Например: \"Я доволен покупкой, спасибо!\"")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack {
                Text("Символов: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Очистить") {
                    text = ""
                    isFocused = false
                }
                .font(.caption)
                .disabled(text.isEmpty)
            }
        }
    }
}
