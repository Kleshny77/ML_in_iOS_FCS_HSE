import SwiftUI

struct MarkdownText: View {
    let content: String
    var font: Font = .body

    private var normalizedContent: String {
        content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                paragraphText(paragraph)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(font)
    }

    private var paragraphs: [String] {
        normalizedContent
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func paragraphText(_ paragraph: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: paragraph,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributed)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(paragraph)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
