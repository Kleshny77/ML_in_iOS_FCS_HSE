


import NaturalLanguage
import CoreML

final class SentimentAnalysisService: SentimentAnalyzing {
    private lazy var customNLModel: NLModel? = {
        // Ищем скомпилированную модель в бандле (.mlmodelc)
        if let url = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc"),
           let mlModel = try? MLModel(contentsOf: url) {
            return try? NLModel(mlModel: mlModel)
        }

        // На случай, если в бандле лежит .mlmodel (например, в тестах)
        if let url = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodel"),
           let mlModel = try? MLModel(contentsOf: url) {
            return try? NLModel(mlModel: mlModel)
        }

        return nil
    }()

    private lazy var toxicityNLModel: NLModel? = {
        if let url = Bundle.main.url(forResource: "ToxicClassifier", withExtension: "mlmodelc"),
           let mlModel = try? MLModel(contentsOf: url) {
            return try? NLModel(mlModel: mlModel)
        }

        if let url = Bundle.main.url(forResource: "ToxicClassifier", withExtension: "mlmodel"),
           let mlModel = try? MLModel(contentsOf: url) {
            return try? NLModel(mlModel: mlModel)
        }

        return nil
    }()
    
    // MARK: - Базовый анализ NLP
    
    func analyze(_ text: String) async throws -> TextAnalysisResult {
        var details: [TextAnalysisResult.AnalysisDetail] = []
        
        // 1. Определение языка
        let language = try await detectLanguage(text)
        details.append(.init(title: "Язык", value: language, type: .info))
        
        // 2. Токенизация и статистика
        let (wordCount, sentences) = try await tokenize(text)
        details.append(.init(title: "Статистика",
                             value: "\(wordCount) слов, \(sentences) предложений",
                             type: .info))

        let words = extractWords(from: text)
        let uniqueWords = Set(words.map { $0.lowercased() }).count
        details.append(.init(title: "Уникальные слова",
                             value: "\(uniqueWords)",
                             type: .info))

        let readability = analyzeReadability(words: words, sentenceCount: sentences)
        details.append(.init(
            title: "Сложность текста",
            value: "\(readability.level) (индекс \(String(format: "%.2f", readability.score)))",
            type: .info
        ))
        
        // 3. Анализ тональности
        var (sentiment, confidence) = try await analyzeSentiment(text)
        
        // 4. Проверка на токсичность (раньше, чтобы попасть в топ-детали)
        let toxicity = analyzeToxicity(text)
        details.append(.init(title: "Токсичность",
                             value: "\(Int(toxicity.score * 100))%",
                             type: toxicity.isToxic ? .warning : .info))
        if toxicity.isToxic {
            // Если текст токсичный, считаем тональность негативной
            sentiment = .negative
            confidence = max(confidence, toxicity.score)
            details.append(.init(title: "⚠️ Предупреждение",
                                 value: "Обнаружен потенциально токсичный контент",
                                 type: .warning))
        }

        let emotion = detectEmotion(
            text: text,
            sentiment: sentiment,
            toxicityScore: toxicity.score
        )
        details.append(.init(title: "Эмоция",
                             value: "\(emotion.emoji) \(emotion.rawValue)",
                             type: .info))
        
        let intent = detectIntent(text)
        details.append(.init(title: "Интент",
                             value: intent.rawValue,
                             type: .info))

        let lemmas = lemmatize(text)
        if !lemmas.isEmpty {
            details.append(.init(title: "Леммы",
                                 value: lemmas.joined(separator: ", "),
                                 type: .info))
        }

        // 5. Определение частей речи
        let posDetails = try await analyzePartsOfSpeech(text)
        details.append(contentsOf: posDetails)
        
        // 6. Поиск именованных сущностей
        let entities = try await findNamedEntities(text)
        if !entities.isEmpty {
            details.append(.init(title: "Именованные сущности",
                                 value: entities.joined(separator: ", "),
                                 type: .info))
        }
        
        return TextAnalysisResult(
            text: text,
            sentiment: sentiment,
            emotion: emotion,
            confidence: confidence,
            toxicityScore: toxicity.score,
            language: language,
            wordCount: wordCount,
            entities: entities,
            details: details,
            timestamp: Date()
        )
    }
    
    // MARK: - Детектирование языка
    
    private func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return "Не определен"
        }
        
        return language.rawValue
    }
    
    // MARK: - Токенизация
    
    private func tokenize(_ text: String) async throws -> (wordCount: Int, sentenceCount: Int) {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        
        var wordCount = 0
        var sentenceCount = 0
        
        // Подсчет слов
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .tokenType,
                             options: [.omitPunctuation, .omitWhitespace]) { _, _ in
            wordCount += 1
            return true
        }
        
        // Подсчет предложений
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .sentence,
                             scheme: .tokenType) { _, _ in
            sentenceCount += 1
            return true
        }
        
        return (wordCount, sentenceCount)
    }

    private func extractWords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text

        var words: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .tokenType,
                             options: [.omitPunctuation, .omitWhitespace]) { _, range in
            words.append(String(text[range]))
            return true
        }
        return words
    }
    
    // MARK: - Анализ тональности
    
    private func analyzeSentiment(_ text: String) async throws -> (Sentiment, Double) {
        // 1) Пробуем кастомную Core ML модель (если добавлена в проект)
        if let model = customNLModel {
            let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 3)
            if let top = hypotheses.max(by: { $0.value < $1.value }) {
                let mapped = mapLabelToSentiment(top.key)
                return (mapped, top.value)
            }
        }

        // 2) Fallback: встроенный анализатор NLTagger
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        if let sentimentTag = tagger.tag(at: text.startIndex,
                                         unit: .paragraph,
                                         scheme: .sentimentScore).0,
           let score = Double(sentimentTag.rawValue) {

            let sentiment: Sentiment
            switch score {
            case 0.3...:
                sentiment = .positive
            case -0.3..<0.3:
                sentiment = .neutral
            default:
                sentiment = .negative
            }

            return (sentiment, abs(score))
        }

        // 3) Безопасный дефолт
        return (.neutral, 0.0)
    }
    
    // MARK: - Кастомная модель
    
    private func mapLabelToSentiment(_ label: String) -> Sentiment {
        let normalized = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.contains("pos") || normalized.contains("позит") {
            return .positive
        }
        if normalized.contains("neg") || normalized.contains("негат") {
            return .negative
        }
        return .neutral
    }

    
    // MARK: - Дополнительные функции NLP
    
    private func analyzePartsOfSpeech(
        _ text: String
    ) async throws -> [TextAnalysisResult.AnalysisDetail] {

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var posCount: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass,
                             options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            if let tag = tag {
                posCount[tag.rawValue, default: 0] += 1
            }
            return true
        }
        
        return posCount.map { TextAnalysisResult.AnalysisDetail(
            title: "Часть речи: \($0.key)",
            value: "\($0.value)",
            type: .info
        )}
    }

    private func lemmatize(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text

        var lemmas: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lemma,
                             options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            if let tag = tag {
                lemmas.append(tag.rawValue)
            }
            return true
        }

        let unique = Array(Set(lemmas))
        return Array(unique.prefix(8)).sorted()
    }

    private func detectIntent(_ text: String) -> Intent {
        let lower = text.lowercased()
        if lower.contains("?") ||
            lower.hasPrefix("как ") || lower.hasPrefix("почему ") || lower.hasPrefix("что ") {
            return .question
        }

        let commandPrefixes = [
            "сделай", "покажи", "дай", "открой", "удали", "запусти", "создай"
        ]
        if commandPrefixes.contains(where: { lower.hasPrefix($0) }) {
            return .command
        }

        let complaintKeywords = [
            "не работает", "сломал", "ужасн", "плох", "кошмар", "жалоб"
        ]
        if complaintKeywords.contains(where: { lower.contains($0) }) {
            return .complaint
        }

        return .statement
    }

    private func detectEmotion(
        text: String,
        sentiment: Sentiment,
        toxicityScore: Double
    ) -> Emotion {
        if toxicityScore >= 0.55 {
            return .anger
        }

        let lower = text.lowercased()
        let joyWords = ["рад", "счаст", "класс", "отлич", "супер", "люблю", "доволен", "ура"]
        let sadnessWords = ["груст", "печал", "тоск", "устал", "разочар", "жаль"]
        let angerWords = ["бесит", "злит", "ненавиж", "ужас", "кошмар", "отстой"]
        let fearWords = ["боюсь", "страш", "тревог", "паник", "опасно"]
        let calmWords = ["спокой", "нормально", "ровно", "стабильно", "тихо"]

        if joyWords.contains(where: { lower.contains($0) }) {
            return .joy
        }
        if sadnessWords.contains(where: { lower.contains($0) }) {
            return .sadness
        }
        if angerWords.contains(where: { lower.contains($0) }) {
            return .anger
        }
        if fearWords.contains(where: { lower.contains($0) }) {
            return .fear
        }
        if calmWords.contains(where: { lower.contains($0) }) {
            return .calm
        }

        switch sentiment {
        case .positive:
            return .joy
        case .negative:
            return .sadness
        case .neutral:
            return .neutral
        }
    }

    private func analyzeReadability(
        words: [String],
        sentenceCount: Int
    ) -> (level: String, score: Double) {
        let wordCount = max(words.count, 1)
        let sentenceCount = max(sentenceCount, 1)
        let totalChars = words.reduce(0) { $0 + $1.count }

        let avgWordLength = Double(totalChars) / Double(wordCount)
        let avgWordsPerSentence = Double(wordCount) / Double(sentenceCount)

        let score = avgWordsPerSentence * 0.5 + avgWordLength * 1.5
        let level: String
        switch score {
        case ..<6:
            level = "Легкий"
        case 6..<9:
            level = "Средний"
        default:
            level = "Сложный"
        }
        return (level, score)
    }
    
    private func findNamedEntities(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: [.joinNames]) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entity = String(text[range])
                entities.append("\(entity) (\(tag.rawValue))")
            }
            return true
        }
        
        return entities
    }
    
    private func analyzeToxicity(_ text: String) -> (isToxic: Bool, score: Double) {
        // 1) Основной вариант — ML модель
        if let model = toxicityNLModel {
            let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 3)
            if !hypotheses.isEmpty {
                var toxicScore = 0.0
                for (label, value) in hypotheses {
                    if isToxicLabel(label) {
                        toxicScore = max(toxicScore, value)
                    }
                }

                // Если не распознали метки, считаем, что токсичность низкая
                let score = toxicScore
                return (score >= 0.5, score)
            }
        }

        // 2) Fallback по ключевым словам
        let toxicPatterns = [
            "идиот", "дурак", "тупой", "ненавижу", "убей", "сдохни"
        ]

        let lowercasedText = text.lowercased()
        let isToxic = toxicPatterns.contains { lowercasedText.contains($0) }
        return (isToxic, isToxic ? 0.7 : 0.0)
    }

    private func isToxicLabel(_ label: String) -> Bool {
        let normalized = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.contains("non") || normalized.contains("clean") || normalized.contains("нет") || normalized.contains("не") {
            return false
        }
        return normalized.contains("toxic") || normalized.contains("токс")
    }
    
    // MARK: - Ошибки
    
    enum AnalysisError: Error {
        case modelNotFound
        case invalidText
        case analysisFailed
    }

    private enum Intent: String {
        case question = "Вопрос"
        case command = "Команда"
        case complaint = "Жалоба"
        case statement = "Утверждение"
    }
}
