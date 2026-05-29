import SwiftUI
import Charts

struct ExerciseProgressChartView: View {
    let exercise: ExerciseType
    @EnvironmentObject var userStats: UserStats
    @State private var selectedMetric: MetricType = .accuracy

    enum MetricType: String, CaseIterable {
        case accuracy = "Точность"
        case performance = "Очки"
        case reactionTime = "Реакция"

        var icon: String {
            switch self {
            case .accuracy: return "target"
            case .performance: return "star.fill"
            case .reactionTime: return "bolt.fill"
            }
        }

        var color: Color {
            switch self {
            case .accuracy: return .green
            case .performance: return .blue
            case .reactionTime: return .orange
            }
        }
    }

    var results: [GameResult] {
        userStats.results(for: exercise).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                metricSelector
                chartSection
                statsSection
                trendSection
            }
            .padding()
        }
        .navigationTitle(exercise.title)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    private var metricSelector: some View {
        Picker("Метрика", selection: $selectedMetric) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                Label(metric.rawValue, systemImage: metric.icon)
                    .tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Динамика за все время")
                .font(.headline)

            if results.count >= 2 {
                Chart(results) { result in
                    LineMark(
                        x: .value("Дата", result.date),
                        y: .value(selectedMetric.rawValue, value(for: result))
                    )
                    .foregroundStyle(selectedMetric.color.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Дата", result.date),
                        y: .value(selectedMetric.rawValue, value(for: result))
                    )
                    .foregroundStyle(selectedMetric.color.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Дата", result.date),
                        y: .value(selectedMetric.rawValue, value(for: result))
                    )
                    .foregroundStyle(selectedMetric.color)
                    .symbolSize(50)
                }
                .frame(height: 250)
                .chartYScale(domain: yDomain)
            } else {
                ContentUnavailableView(
                    "Недостаточно данных",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Нужно минимум 2 тренировки")
                )
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatBoxChart(
                title: "Всего",
                value: "\(results.count)",
                icon: "number.circle.fill",
                color: .blue
            )

            StatBoxChart(
                title: "Точность",
                value: String(format: "%.0f%%", averageAccuracy() * 100),
                icon: "target",
                color: .green
            )

            StatBoxChart(
                title: "Лучший",
                value: String(format: "%.0f", bestScore()),
                icon: "star.circle.fill",
                color: .yellow
            )

            StatBoxChart(
                title: "Реакция",
                value: String(format: "%.2fс", averageTime()),
                icon: "clock.fill",
                color: .orange
            )
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Анализ прогресса")
                .font(.headline)

            if results.count >= 3 {
                let trend = calculateTrend()
                HStack(spacing: 16) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 40))
                        .foregroundColor(trend.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(trend.title)
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(trend.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(trend.color.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("Нужно минимум 3 тренировки для анализа")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func value(for result: GameResult) -> Double {
        switch selectedMetric {
        case .accuracy: return result.accuracy * 100
        case .performance: return result.performanceScore
        case .reactionTime: return result.averageReactionTime
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = results.map { value(for: $0) }
        guard let min = values.min(), let max = values.max() else { return 0...100 }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }

    private func averageAccuracy() -> Double {
        guard !results.isEmpty else { return 0 }
        return results.map { $0.accuracy }.reduce(0, +) / Double(results.count)
    }

    private func bestScore() -> Double {
        results.map { $0.performanceScore }.max() ?? 0
    }

    private func averageTime() -> Double {
        guard !results.isEmpty else { return 0 }
        return results.map { $0.averageReactionTime }.reduce(0, +) / Double(results.count)
    }

    private func calculateTrend() -> TrendInfo {
        let firstHalf = Array(results.prefix(results.count / 2))
        let secondHalf = Array(results.suffix(results.count / 2))

        let firstAvg = firstHalf.map { $0.performanceScore }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.performanceScore }.reduce(0, +) / Double(secondHalf.count)

        let diff = secondAvg - firstAvg
        let percentChange = firstAvg > 0 ? (diff / firstAvg) * 100 : 0

        if diff > 10 {
            return TrendInfo(
                title: "Улучшение",
                description: String(format: "+%.0f%% к результату", abs(percentChange)),
                icon: "arrow.up.forward.circle.fill",
                color: .green
            )
        } else if diff < -10 {
            return TrendInfo(
                title: "Снижение",
                description: String(format: "-%.0f%% от результата", abs(percentChange)),
                icon: "arrow.down.forward.circle.fill",
                color: .red
            )
        } else {
            return TrendInfo(
                title: "Стабильно",
                description: "Без значительных изменений",
                icon: "arrow.right.circle.fill",
                color: .blue
            )
        }
    }
}

struct TrendInfo {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct StatBoxChart: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ExerciseProgressChartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseProgressChartView(exercise: .schulte)
                .environmentObject(UserStats())
        }
    }
}
