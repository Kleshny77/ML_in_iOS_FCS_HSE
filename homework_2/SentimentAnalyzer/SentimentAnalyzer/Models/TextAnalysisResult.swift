//
//  SentimentAnalyzer.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 23.01.2026.
//

import Foundation
import SwiftUI

enum Sentiment: String, Codable {
    case positive = "Позитивный"
    case negative = "Негативный"
    case neutral = "Нейтральный"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😠"
        case .neutral: return "😐"
        }
    }
}

enum Emotion: String, Codable {
    case joy = "Радость"
    case sadness = "Грусть"
    case anger = "Злость"
    case fear = "Тревога"
    case calm = "Спокойствие"
    case neutral = "Нейтрально"

    var color: Color {
        switch self {
        case .joy: return .yellow
        case .sadness: return .blue
        case .anger: return .red
        case .fear: return .orange
        case .calm: return .mint
        case .neutral: return .gray
        }
    }

    var emoji: String {
        switch self {
        case .joy: return "😄"
        case .sadness: return "😢"
        case .anger: return "😡"
        case .fear: return "😨"
        case .calm: return "😌"
        case .neutral: return "😐"
        }
    }
}

struct TextAnalysisResult: Codable {
    let text: String
    let sentiment: Sentiment
    let emotion: Emotion?
    let confidence: Double
    let toxicityScore: Double?
    let language: String
    let wordCount: Int
    let entities: [String]
    let details: [AnalysisDetail]
    let timestamp: Date
    
    struct AnalysisDetail: Codable {
        let title: String
        let value: String
        let type: DetailType
        
        enum DetailType: String, Codable {
            case info, warning, success, error
        }
    }
}
