//
//  SentimentAnalyzerApp.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import SwiftUI

@main
struct SentimentAnalyzerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState
    private let sentimentComponent: any SentimentComponentProtocol

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)

        let di = AppDI.shared
        self.sentimentComponent = SentimentComponent(
            sentimentAnalyzer: di.sentimentAnalyzer,
            quickAnalyzer: di.quickAnalyzer,
            historyStore: di.historyStore,
            exportService: di.exportService,
            sharedTextConsumer: di.sharedTextConsumer
        )

        appDelegate.appState = state
    }

    var body: some Scene {
        WindowGroup {
            sentimentComponent.view.eraseToAnyView()
                .environmentObject(appState)
        }
    }
}
