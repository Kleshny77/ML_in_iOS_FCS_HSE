# Widget Integration Notes

The widget source is ready in this folder, but the current Xcode project contains only one app target.

To enable the Home Screen widget:

1. In Xcode: `File` -> `New` -> `Target...` -> `Widget Extension`.
2. Name it, for example, `SentimentWidgetExtension`.
3. Move or add `SentimentSummaryWidget.swift` to the new extension target.
4. Enable App Group capability for both targets with:
   `group.com.example.SentimentAnalyzer`
5. Keep history storage key as `analysisHistory` (already used by the app).

After that, the widget will read app history and show sentiment + toxicity summary.
