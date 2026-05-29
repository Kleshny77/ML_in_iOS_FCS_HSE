//
//  AppDelegate.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    weak var appState: AppState?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "newAnalysis",
                localizedTitle: "Новый анализ",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.bubble"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "openHistory",
                localizedTitle: "История",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "clock"),
                userInfo: nil
            )
        ]
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        switch shortcutItem.type {
        case "newAnalysis":
            appState?.quickAction = .newAnalysis
            completionHandler(true)
        case "openHistory":
            appState?.quickAction = .openHistory
            completionHandler(true)
        default:
            completionHandler(false)
        }
    }
}
