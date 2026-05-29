//
//  SentimentComponentProtocol.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 27.02.2026.
//

import SwiftUI

public protocol SentimentComponentProtocol {
    associatedtype Body: View

    @MainActor
    var view: Body { get }
}
