import UIKit
import Social
import NaturalLanguage
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    private let pasteboardPrefix = "sentiment_shared://"
    private var receivedText: String = ""
    private var analysisSummary: String = "Нет текста для анализа"

    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        loadSharedText()
    }

    override func isContentValid() -> Bool {
        let text = normalizedText()
        analysisSummary = analyze(text: text)
        return !text.isEmpty
    }

    override func didSelectPost() {
        let text = normalizedText()
        guard !text.isEmpty else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let defaults = UserDefaults(suiteName: "group.com.example.SentimentAnalyzer")
        defaults?.set(text, forKey: "incomingSharedText")
        defaults?.synchronize()

        UIPasteboard.general.string = "\(pasteboardPrefix)\(text)"

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        let item = SLComposeSheetConfigurationItem()
        item?.title = "Быстрый анализ"
        item?.value = analysisSummary
        item?.tapHandler = {}
        return [item as Any]
    }
}

private extension ShareViewController {
    func loadSharedText() {
        extractTextFromAttachments { [weak self] text in
            guard let self else { return }

            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                self.analysisSummary = self.analyze(text: self.normalizedText())
                self.reloadConfigurationItems()
                return
            }

            self.receivedText = cleaned
            self.analysisSummary = self.analyze(text: self.normalizedText())
            self.reloadConfigurationItems()
        }
    }

    func extractTextFromAttachments(completion: @escaping (String) -> Void) {
        guard
            let items = extensionContext?.inputItems as? [NSExtensionItem],
            !items.isEmpty
        else {
            completion(contentText ?? "")
            return
        }

        let providers = items
            .flatMap { $0.attachments ?? [] }

        guard !providers.isEmpty else {
            completion(contentText ?? "")
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var parts: [String] = []

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    guard let text = self.stringValue(from: item), !text.isEmpty else { return }
                    lock.lock()
                    parts.append(text)
                    lock.unlock()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    guard let urlText = self.urlValue(from: item), !urlText.isEmpty else { return }
                    lock.lock()
                    parts.append(urlText)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            let merged = ([self.contentText ?? ""] + parts)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            completion(merged)
        }
    }

    func stringValue(from item: NSSecureCoding?) -> String? {
        if let text = item as? String {
            return text
        }
        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        if let url = item as? URL {
            return url.absoluteString
        }
        return nil
    }

    func urlValue(from item: NSSecureCoding?) -> String? {
        if let url = item as? URL {
            return url.absoluteString
        }
        if let data = item as? Data,
           let urlString = String(data: data, encoding: .utf8) {
            return urlString
        }
        return nil
    }

    func normalizedText() -> String {
        let text = (contentText ?? receivedText).trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }

    func analyze(text: String) -> String {
        guard !text.isEmpty else { return "Нет текста для анализа" }

        let sentiment = analyzeSentimentScore(text)
        let toxicity = estimateToxicity(text)
        let summary = "\(sentiment.label) · токсичность \(Int(toxicity * 100))%"
        return summary
    }

    func analyzeSentimentScore(_ text: String) -> (label: String, score: Double) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let value: Double
        if let tag = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        ).0,
           let score = Double(tag.rawValue) {
            value = score
        } else {
            value = 0.0
        }

        let label: String
        switch value {
        case 0.25...:
            label = "Позитив"
        case ..<(-0.25):
            label = "Негатив"
        default:
            label = "Нейтрально"
        }

        return (label, value)
    }

    func estimateToxicity(_ text: String) -> Double {
        let lower = text.lowercased()
        let toxicWords = ["идиот", "дурак", "тупой", "ненавижу", "сдохни", "убей"]
        let hits = toxicWords.filter { lower.contains($0) }.count
        return min(Double(hits) * 0.35, 1.0)
    }
}
