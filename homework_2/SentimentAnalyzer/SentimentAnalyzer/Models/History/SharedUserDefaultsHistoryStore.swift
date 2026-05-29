//
//  SharedUserDefaultsHistoryStore.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation

final class SharedUserDefaultsHistoryStore: AnalysisHistoryStoring {
    private let userDefaults: UserDefaults
    private let historyKey: String

    init(
        userDefaults: UserDefaults = SharedStore.userDefaults,
        historyKey: String = SharedStore.historyKey
    ) {
        self.userDefaults = userDefaults
        self.historyKey = historyKey
    }

    func loadHistory() -> [TextAnalysisResult] {
        guard
            let data = userDefaults.data(forKey: historyKey),
            !data.isEmpty,
            let decoded = try? JSONDecoder().decode([TextAnalysisResult].self, from: data)
        else {
            return []
        }
        return decoded
    }

    func saveHistory(_ history: [TextAnalysisResult]) {
        guard let encoded = try? JSONEncoder().encode(history) else {
            userDefaults.set(Data(), forKey: historyKey)
            return
        }
        userDefaults.set(encoded, forKey: historyKey)
    }
}
