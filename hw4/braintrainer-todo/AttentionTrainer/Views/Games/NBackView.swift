import SwiftUI

struct NBackView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = NBackViewModel()
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

            Spacer()

            stimulusDisplay

            Spacer()

            if selectedDifficulty.rawValue <= 3 {
                historyView

                Spacer()
            }

            controlsArea
        }
        .padding()
        .navigationTitle("N-Back (\(viewModel.n)-back)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .nback)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .nback)
            viewModel.setup(difficulty: selectedDifficulty)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Раунд \(viewModel.currentIteration)/\(viewModel.totalIterations)")
                    .font(.headline)

                if viewModel.isGameActive {
                    Text("Нажмите, когда буква повторяется через \(viewModel.n)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            ProgressView(value: Double(viewModel.currentIteration), total: Double(viewModel.totalIterations))
                .frame(width: 100)
        }
    }

    private var stimulusDisplay: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 200, height: 200)

            if viewModel.isGameActive {
                Text(viewModel.currentStimulus)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .transition(.scale.combined(with: .opacity))
                    .id(viewModel.currentStimulus)
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStimulus)
    }

    private var historyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("История")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(viewModel.stimulusHistory.count)/\(viewModel.totalIterations)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {

                    let displayCount = min(viewModel.stimulusHistory.count, 10)
                    let startIndex = max(0, viewModel.stimulusHistory.count - 10)

                    ForEach(Array(viewModel.stimulusHistory[startIndex..<startIndex+displayCount].enumerated()), id: \.offset) { offset, stimulus in
                        let actualIndex = startIndex + offset
                        Text(stimulus)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(backgroundColor(for: actualIndex))
                            )
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(height: 40)

            .padding(.leading, -16)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var controlsArea: some View {
        VStack(spacing: 16) {

            if viewModel.isGameActive {
                Button(action: {
                    viewModel.userResponded()
                }) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("Совпадение!")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

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

    private func backgroundColor(for index: Int) -> Color {

        if index >= viewModel.n {
            let current = viewModel.stimulusHistory[index]
            let previous = viewModel.stimulusHistory[index - viewModel.n]
            if current == previous {
                return .green.opacity(0.3)
            }
        }
        return Color(.tertiarySystemFill)
    }

    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }

        session = ExerciseSession(
            exerciseType: .nback,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )

        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)

            let recent = userStats.results(for: .nback, last: 5)
            lastRecommendation = adaptiveEngine.analyze(
                exercise: .nback,
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
            for: .nback,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .nback, to: nextDifficulty)
        viewModel.setup(difficulty: nextDifficulty)
        viewModel.resetGame()
    }

    private func levelColor(_ level: DifficultyLevel) -> Color {
        switch level.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .gray
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
