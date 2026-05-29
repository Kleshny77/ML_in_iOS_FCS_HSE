//
//  SentimentSummaryWidgetLiveActivity.swift
//  SentimentSummaryWidget
//
//  Created by Karabelnikov Stepan on 26.02.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SentimentSummaryWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SentimentSummaryWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SentimentSummaryWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SentimentSummaryWidgetAttributes {
    fileprivate static var preview: SentimentSummaryWidgetAttributes {
        SentimentSummaryWidgetAttributes(name: "World")
    }
}

extension SentimentSummaryWidgetAttributes.ContentState {
    fileprivate static var smiley: SentimentSummaryWidgetAttributes.ContentState {
        SentimentSummaryWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SentimentSummaryWidgetAttributes.ContentState {
         SentimentSummaryWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SentimentSummaryWidgetAttributes.preview) {
   SentimentSummaryWidgetLiveActivity()
} contentStates: {
    SentimentSummaryWidgetAttributes.ContentState.smiley
    SentimentSummaryWidgetAttributes.ContentState.starEyes
}
