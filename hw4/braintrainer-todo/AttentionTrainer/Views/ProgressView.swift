import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject var userStats: UserStats

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summarySection

                activityChartSection
                distributionChartSection

                skillsSection
                exerciseStatsSection
            }
            .padding()
        }
        .navigationTitle("Прогресс")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    private var summarySection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Всего тренировок",
                value: "\(userStats.history.count)",
                icon: "checkmark.circle.fill",
                color: .blue
            )

            SummaryCard(
                title: "Текущая серия",
                value: "\(userStats.streak) дней",
                icon: "flame.fill",
                color: .orange
            )

            SummaryCard(
                title: "Общее время",
                value: formatDuration(userStats.totalTrainingTime()),
                icon: "clock.fill",
                color: .green
            )

            SummaryCard(
                title: "Средняя точность",
                value: String(format: "%.0f%%", overallAccuracy() * 100),
                icon: "target",
                color: .purple
            )
        }
    }

    private var activityChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Активность за 7 дней")
                .font(.title2)
                .fontWeight(.bold)

            let last7Days = last7DaysData()

            if last7Days.contains(where: { $0.count > 0 }) {
                Chart(last7Days) { day in
                    BarMark(
                        x: .value("День", day.date, unit: .day),
                        y: .value("Тренировки", day.count)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.short))
                    }
                }
            } else {
                ContentUnavailableView(
                    "Нет активности",
                    systemImage: "chart.bar",
                    description: Text("Тренируйтесь, чтобы увидеть статистику")
                )
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var distributionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Распределение по упражнениям")
                .font(.title2)
                .fontWeight(.bold)

            let distribution = exerciseDistribution()

            if !distribution.isEmpty {
                HStack(spacing: 20) {

                    Chart(distribution) { item in
                        SectorMark(
                            angle: .value("Количество", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Упражнение", item.exercise.title))
                        .cornerRadius(4)
                    }
                    .frame(height: 180)
                    .chartLegend(position: .trailing, alignment: .center)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(distribution) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForExercise(item.exercise))
                                    .frame(width: 10, height: 10)

                                Text(item.exercise.title)
                                    .font(.caption)

                                Spacer()

                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .frame(width: 120)
                }
            } else {
                ContentUnavailableView(
                    "Нет данных",
                    systemImage: "chart.pie",
                    description: Text("Начните тренироваться")
                )
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Развитие навыков")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(userStats.allSkills, id: \.name) { skill in
                    SkillBar(name: skill.name, progress: skill.progress)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var exerciseStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Детальная статистика")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                ForEach(ExerciseType.allCases) { exercise in
                    NavigationLink(destination: ExerciseProgressChartView(exercise: exercise)) {
                        ExerciseStatRowChart(
                            exercise: exercise,
                            count: userStats.results(for: exercise).count,
                            avgPerformance: userStats.averagePerformance(for: exercise)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func overallAccuracy() -> Double {
        guard !userStats.history.isEmpty else { return 0 }
        return userStats.history.map { $0.accuracy }.reduce(0, +) / Double(userStats.history.count)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return hours > 0 ? "\(hours)ч \(minutes)м" : "\(minutes) мин"
    }

    private func last7DaysData() -> [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let count = userStats.history.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }.count
            return DayActivity(date: date, count: count)
        }.reversed()
    }

    private func exerciseDistribution() -> [ExerciseCount] {
        ExerciseType.allCases.map { exercise in
            let count = userStats.results(for: exercise, last: 9999).count
            return ExerciseCount(exercise: exercise, count: count)
        }.filter { $0.count > 0 }
    }

    private func colorForExercise(_ exercise: ExerciseType) -> Color {
        switch exercise {
        case .schulte: return .blue
        case .nback: return .green
        case .numbers: return .orange
        case .colors: return .purple
        }
    }
}

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct ExerciseCount: Identifiable {
    let exercise: ExerciseType
    let count: Int

    var id: String { exercise.rawValue }
}

struct SummaryCard: View {
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
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SkillBar: View {
    let name: String
    let progress: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.subheadline)
                .frame(width: 140, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                        .frame(width: max(0, geo.size.width * CGFloat(progress) / 100))
                }
            }
            .frame(height: 8)

            Text("\(Int(progress))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .green],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct ExerciseStatRowChart: View {
    let exercise: ExerciseType
    let count: Int
    let avgPerformance: Double

    var body: some View {
        HStack {
            Image(systemName: exercise.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(exercise.title)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 16) {
                Label("\(count)", systemImage: "number")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if avgPerformance > 0 {
                    Text(String(format: "%.0f", avgPerformance))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProgressDashboardView()
                .environmentObject(UserStats())
        }
    }
}
