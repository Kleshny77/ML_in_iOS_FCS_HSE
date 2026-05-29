import SwiftUI

struct CandlestickChartView: View {
    let candles: [FCSHistoryCandle]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard candles.count >= 2,
                      let minPrice = candles.compactMap({ $0.parsedLow }).min(),
                      let maxPrice = candles.compactMap({ $0.parsedHigh }).max() else {
                    context.draw(
                        Text("Недостаточно данных").font(.caption),
                        at: CGPoint(x: size.width / 2, y: size.height / 2)
                    )
                    return
                }

                let padding: CGFloat = 8
                let chartWidth = size.width - padding * 2
                let chartHeight = size.height - padding * 2
                let candleWidth = chartWidth / CGFloat(candles.count) * 0.7
                let spacing = chartWidth / CGFloat(candles.count)
                let priceRange = maxPrice - minPrice

                for (index, candle) in candles.enumerated() {
                    guard let open = candle.parsedOpen,
                          let high = candle.parsedHigh,
                          let low = candle.parsedLow,
                          let close = candle.parsedClose else { continue }

                    let x = padding + CGFloat(index) * spacing + spacing / 2
                    let yHigh = padding + chartHeight - CGFloat((high - minPrice) / priceRange) * chartHeight
                    let yLow = padding + chartHeight - CGFloat((low - minPrice) / priceRange) * chartHeight
                    let yOpen = padding + chartHeight - CGFloat((open - minPrice) / priceRange) * chartHeight
                    let yClose = padding + chartHeight - CGFloat((close - minPrice) / priceRange) * chartHeight

                    let isBullish = close >= open
                    let color = isBullish ? Color.green : Color.red

                    var wick = Path()
                    wick.move(to: CGPoint(x: x, y: yHigh))
                    wick.addLine(to: CGPoint(x: x, y: yLow))
                    context.stroke(wick, with: .color(color), lineWidth: 1)

                    let bodyTop = min(yOpen, yClose)
                    let bodyBottom = max(yOpen, yClose)
                    let bodyHeight = max(bodyBottom - bodyTop, 1)
                    let bodyRect = CGRect(
                        x: x - candleWidth / 2,
                        y: bodyTop,
                        width: candleWidth,
                        height: bodyHeight
                    )
                    context.fill(Path(bodyRect), with: .color(color))
                }

                let topText = Text(String(format: "%.5f", maxPrice)).font(.system(size: 8))
                let bottomText = Text(String(format: "%.5f", minPrice)).font(.system(size: 8))
                context.draw(topText, at: CGPoint(x: size.width - 30, y: padding))
                context.draw(bottomText, at: CGPoint(x: size.width - 30, y: size.height - padding))
            }
        }
    }
}
