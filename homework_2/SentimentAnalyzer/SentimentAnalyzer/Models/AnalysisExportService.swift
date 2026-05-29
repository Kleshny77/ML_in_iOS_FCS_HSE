//
//  AnalysisExportService.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import Foundation
import UIKit

enum AnalysisExportService {
    static func makeText(from result: TextAnalysisResult) -> String {
        var lines: [String] = []
        lines.append("Анализ тональности")
        lines.append("Дата: \(formatDate(result.timestamp))")
        lines.append("")
        lines.append("Текст:")
        lines.append(result.text)
        lines.append("")
        lines.append("Результат: \(result.sentiment.rawValue) \(result.sentiment.emoji)")
        if let emotion = result.emotion {
            lines.append("Эмоция: \(emotion.rawValue) \(emotion.emoji)")
        }
        lines.append("Уверенность: \(Int(result.confidence * 100))%")
        if let toxicity = result.toxicityScore {
            lines.append("Токсичность: \(Int(toxicity * 100))%")
        }
        lines.append("Язык: \(result.language)")
        lines.append("Слов: \(result.wordCount)")
        if !result.entities.isEmpty {
            lines.append("Сущности: \(result.entities.joined(separator: ", "))")
        }
        if !result.details.isEmpty {
            lines.append("")
            lines.append("Детали:")
            for detail in result.details {
                lines.append("• \(detail.title): \(detail.value)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func makePDFData(from result: TextAnalysisResult) -> Data {
        let text = makeText(from: result)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]

            let textRect = pageRect.insetBy(dx: 40, dy: 40)
            text.draw(in: textRect, withAttributes: attributes)
        }

        return data
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
