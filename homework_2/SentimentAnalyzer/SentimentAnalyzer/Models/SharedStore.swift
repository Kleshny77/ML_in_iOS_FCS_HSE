//
//  SharedStore.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation

enum SharedStore {
    static let appGroupID = "group.com.example.SentimentAnalyzer"
    static let historyKey = "analysisHistory"
    static let incomingSharedTextKey = "incomingSharedText"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
