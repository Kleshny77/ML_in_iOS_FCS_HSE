//
//  AppState.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    enum QuickAction {
        case newAnalysis
        case openHistory
    }

    @Published var quickAction: QuickAction?
}
