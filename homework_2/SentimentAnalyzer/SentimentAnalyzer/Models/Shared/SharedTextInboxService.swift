//
//  SharedTextInboxService.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import Foundation
import UIKit

final class SharedTextInboxService: SharedTextConsuming {
    private let userDefaults: UserDefaults
    private let incomingTextKey: String
    private let pasteboardPrefix: String

    init(
        userDefaults: UserDefaults = SharedStore.userDefaults,
        incomingTextKey: String = SharedStore.incomingSharedTextKey,
        pasteboardPrefix: String = "sentiment_shared://"
    ) {
        self.userDefaults = userDefaults
        self.incomingTextKey = incomingTextKey
        self.pasteboardPrefix = pasteboardPrefix
    }

    func consumeSharedText() -> String? {
        let fromDefaults = userDefaults.string(forKey: incomingTextKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let fromDefaults, !fromDefaults.isEmpty {
            userDefaults.removeObject(forKey: incomingTextKey)
            return fromDefaults
        }

        guard
            let clipboard = UIPasteboard.general.string,
            clipboard.hasPrefix(pasteboardPrefix)
        else {
            return nil
        }

        let extracted = String(clipboard.dropFirst(pasteboardPrefix.count))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        UIPasteboard.general.string = nil
        return extracted.isEmpty ? nil : extracted
    }
}
