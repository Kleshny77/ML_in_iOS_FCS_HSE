import SwiftUI

struct NumbersView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var viewModel = NumbersViewModel()
    @StateObject private var adaptiveEngine = AdaptiveEngine()

    @State private var selectedDifficulty: DifficultyLevel = .level1
    @State private var showResultSheet = false
    @State private var showInfoSheet = false
    @State private var session: ExerciseSession?
    @State private var lastRecommendation: DifficultyRecommendation = .maintain
    @State private var lastAnalysis: AnalysisResult?

    var body: some View {
        VStack(spacing: 16) {
            headerView

            if viewModel.showCenter && viewModel.isGameActive {
                centerHintsView
            }

            gameColumns

            Spacer()

            controlsArea
        }
        .padding()
        .navigationTitle("Поиск чисел")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showInfoSheet = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ExerciseInfoSheet(exercise: .numbers)
        }
        .onAppear {
            selectedDifficulty = userStats.recommendedDifficulty(for: .numbers)
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
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(formatTime(viewModel.elapsedTime))
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.semibold)
            }

            Spacer()

            if selectedDifficulty.rawValue >= 7 {
                HStack(spacing: 8) {
                    Label("\(viewModel.foundPairs.count)", systemImage: "checkmark.circle")
                        .font(.caption)
                    Label("\(viewModel.wrongAttempts)", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                HStack(spacing: 4) {
                    Text("Найдено: \(viewModel.foundPairs.count)")
                        .font(.subheadline)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                    Text("\(viewModel.wrongAttempts)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var centerHintsView: some View {
        VStack(spacing: 8) {
            Text("Ищите эти числа:")
                .font(.caption)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.centerNumbers, id: \.self) { number in
                    if viewModel.foundPairs.contains(number) {
                        EmptyView()
                    } else {
                        Text("\(number)")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.2))
                            )
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var gameColumns: some View {
        HStack(spacing: 20) {

            VStack(spacing: 8) {
                Text("Левая")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(viewModel.leftColumn, id: \.self) { number in
                    numberButton(number, side: .left)
                }
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)

            VStack(spacing: 8) {
                Text("Правая")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(viewModel.rightColumn, id: \.self) { number in
                    numberButton(number, side: .right)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func numberButton(_ number: Int, side: NumbersViewModel.Side) -> some View {
        let isFound = viewModel.foundPairs.contains(number)

        return Button(action: {
            viewModel.selectNumber(number, fromSide: side)
        }) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFound ? Color.green : Color(.tertiarySystemFill))
                )
                .foregroundColor(isFound ? .white : .primary)
        }
        .disabled(isFound || !viewModel.isGameActive)
        .buttonStyle(PlainButtonStyle())
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

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func finishGame() {
        guard let metrics = viewModel.getSessionMetrics() else { return }

        session = ExerciseSession(
            exerciseType: .numbers,
            difficulty: selectedDifficulty,
            startTime: Date().addingTimeInterval(-metrics.totalTime),
            endTime: Date(),
            metrics: metrics
        )

        if let session = session {
            let result = GameResult(from: session)
            userStats.addResult(result)

            let recent = userStats.results(for: .numbers, last: 5)
            lastRecommendation = adaptiveEngine.analyze(
                exercise: .numbers,
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
            for: .numbers,
            current: selectedDifficulty,
            in: userStats
        )
        selectedDifficulty = nextDifficulty
        userStats.updateDifficulty(for: .numbers, to: nextDifficulty)
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
