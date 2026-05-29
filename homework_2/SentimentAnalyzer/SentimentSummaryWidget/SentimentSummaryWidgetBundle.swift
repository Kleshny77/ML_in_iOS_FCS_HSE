//
//  SentimentSummaryWidgetBundle.swift
//  SentimentSummaryWidget
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import WidgetKit
import SwiftUI

@main
struct SentimentSummaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentimentSummaryWidget()
        SentimentSummaryWidgetControl()
        SentimentSummaryWidgetLiveActivity()
    }
}
