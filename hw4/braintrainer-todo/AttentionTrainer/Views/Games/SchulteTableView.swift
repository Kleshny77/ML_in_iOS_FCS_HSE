import SwiftUI

struct SchulteTableView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = SchulteViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()

    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    @State private var lastRecommendation: DifficultyRecommendation = .maintain
    @State private var lastAnalysis: AnalysisResult?

    var body: some View {
        VStack(spacing: 20) {

            headerView

            gameArea

            if viewModel.isGameActive {
                targetIndicator
            }

            Spacer()

            controlsArea
        }
        .padding()
        .navigationTitle("Таблица Шульте")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .schulte)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .schulte)
            viewModel.setup(difficulty: selectedDifficulty)
        }
        .onChange(of: selectedDifficulty) { _, newValue in
            viewModel.setup(difficulty: newValue)
        }
        .onChange(of: viewModel.isGameCompleted) { _, completed in
            if completed {
                finishGame()
            }
        }
        .sheet(isPresented: $showResultSheet) {
            ResultSheet(
                session: session,
                recommendation: lastRecommendation,
                analysis: lastAnalysis,
                onContinue: {
                    showResultSheet = false
                }
            )
        }
    }

    private var headerView: some View {
        HStack {

            HStack {
                Image(systemName: "clock")
                Text(formatTime(viewModel.elapsedTime))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
            }

            Spacer()

            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                Text("\(viewModel.wrongAttempts)")
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal)
    }

    private var gameArea: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.gridSize)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<viewModel.numbers.count, id: \.self) { index in
                let number = viewModel.numbers[index]
                let isSelected = viewModel.selectedIndices.contains(index)
                let isNext = number == viewModel.currentTarget

                Button(action: {
                    viewModel.selectNumber(at: index)
                }) {
                    Text("\(number)")
                        .font(.system(size: fontSize, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(backgroundColor(for: index, isSelected: isSelected, isNext: isNext))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .disabled(isSelected || !viewModel.isGameActive)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var targetIndicator: some View {
        HStack {
            Text(viewModel.isReverseMode ? "Ищите:" : "Ищите:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Image(systemName: viewModel.isReverseMode ? "arrow.down" : "arrow.up")
                .font(.caption)
                .foregroundColor(.accentColor)

            Text("\(viewModel.currentTarget)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .frame(minWidth: 50)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
        )
    }

    private var controlsArea: some View {
        VStack(spacing: 12) {
            if !viewModel.isGameActive && !viewModel.isGameCompleted {
                VStack(spacing: 8) {
                    HStack {
                        Text("Уровень сложности")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(selectedDifficulty.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            if selectedDifficulty.rawValue > DifficultyLevel.min {
                                selectedDifficulty = DifficultyLevel(rawValue: selectedDifficulty.rawValue - 1) ?? selectedDifficulty
                                viewModel.setup(difficulty: selectedDifficulty)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedDifficulty.rawValue > DifficultyLevel.min ? .accentColor : .gray.opacity(0.3))
                        }
                        .disabled(selectedDifficulty.rawValue <= DifficultyLevel.min)

                        HStack(spacing: 4) {
                            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                Circle()
                                    .fill(level.rawValue <= selectedDifficulty.rawValue ? levelColor(level) : Color.gray.opacity(0.2))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Button(action: {
                            if selectedDifficulty.rawValue < DifficultyLevel.max {
                                selectedDifficulty = DifficultyLevel(rawValue: selectedDifficulty.rawValue + 1) ?? selectedDifficulty
                                viewModel.setup(difficulty: selectedDifficulty)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedDifficulty.rawValue < DifficultyLevel.max ? .accentColor : .gray.opacity(0.3))
                        }
                        .disabled(selectedDifficulty.rawValue >= DifficultyLevel.max)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }

            Button(action: {
                if viewModel.isGameActive {
                    viewModel.resetGame()
                } else {
                    viewModel.startGame()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isGameActive ? "stop.fill" : "play.fill")
                    Text(viewModel.isGameActive ? "Стоп" : "Начать")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isGameActive ? Color.red : Color.accentColor)
                .cornerRadius(12)
            }
        }
    }

    private func levelColor(_ level: DifficultyLevel) -> Color {
        switch level.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .gray
        }
    }

    private var fontSize: CGFloat {
        switch viewModel.gridSize {
        case 3: return 32
        case 4: return 28
        case 5: return 24
        case 6: return 20
        case 7: return 18
        case 8: return 16
        case 9: return 14
        case 10: return 12
        default: return 20
        }
    }

    private func backgroundColor(for index: Int, isSelected: Bool, isNext: Bool) -> Color {
        if isSelected {
            return .green
        } else if isNext && !viewModel.isGameActive {
            return .accentColor.opacity(0.3)
        } else {
            return Color(.tertiarySystemFill)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let tenths = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }

    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }

        session = ExerciseSession(
            exerciseType: .schulte,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )

        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)

            let recent = userStats.results(for: .schulte, last: 5)
            lastRecommendation = adaptiveEngine.analyze(
                exercise: .schulte,
                recentResults: recent,
                currentLevel: selectedDifficulty
            )
            lastAnalysis = adaptiveEngine.analysisResult

            applyRecommendation()

            showResultSheet = true
        }
    }

    private func applyRecommendation() {
        let nextDifficulty = adaptiveEngine.nextDifficulty(
            for: .schulte,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .schulte, to: nextDifficulty)
        viewModel.setup(difficulty: nextDifficulty)
        viewModel.resetGame()
    }
}

struct ResultSheet: View {
    let session: ExerciseSession?
    let recommendation: DifficultyRecommendation
    let analysis: AnalysisResult?
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    successIcon

                    if let metrics = session?.metrics {
                        statsGrid(metrics: metrics)
                    }

                    if let analysis = analysis {
                        analysisSection(analysis: analysis)
                    }

                    recommendationSection

                    Spacer()

                    Button(action: onContinue) {
                        Text("Продолжить")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Результат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                        onContinue()
                    }
                }
            }
        }
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.top, 20)
    }

    private func statsGrid(metrics: SessionMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatBox(title: "Время", value: formatTime(metrics.totalTime), color: .blue)
            StatBox(title: "Точность", value: String(format: "%.0f%%", metrics.accuracy * 100), color: .green)
            StatBox(title: "Ошибок", value: "\(metrics.incorrectAnswers)", color: .red)
            StatBox(title: "Очки", value: String(format: "%.0f", metrics.performanceScore), color: .orange)
        }
    }

    private func analysisSection(analysis: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Анализ производительности")
                .font(.headline)

            VStack(spacing: 8) {
                AnalysisRow(title: "Средняя точность", value: analysis.formattedAccuracy)
                AnalysisRow(title: "Средний результат", value: analysis.formattedPerformance)
                AnalysisRow(title: "Время реакции", value: analysis.formattedReactionTime)
                AnalysisRow(
                    title: "Тренд",
                    value: analysis.trend.title,
                    systemImage: analysis.trend.icon
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var recommendationSection: some View {
        VStack(spacing: 12) {
            Text("Рекомендация")
                .font(.headline)

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: recommendationIcon)
                    .font(.title2)
                    .foregroundColor(recommendationColor)
                Text(recommendation.description)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(recommendationColor.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var recommendationIcon: String {
        switch recommendation {
        case .upgrade: return "arrow.up.circle.fill"
        case .downgrade: return "arrow.down.circle.fill"
        case .maintain: return "checkmark.circle.fill"
        }
    }

    private var recommendationColor: Color {
        switch recommendation {
        case .upgrade: return .green
        case .downgrade: return .orange
        case .maintain: return .blue
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    var systemImage: String?

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            if let systemImage {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundColor(.accentColor)
                    Text(value)
                        .fontWeight(.medium)
                }
            } else {
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
}
