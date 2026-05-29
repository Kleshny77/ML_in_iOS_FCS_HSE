import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var userStats: UserStats
    @StateObject private var adaptiveEngine = AdaptiveEngine()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    headerView

                    statsSummaryView

                    exercisesSection

                    skillsProgressSection
                }
                .padding()
            }
            .navigationTitle("Тренировка памяти")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProgressDashboardView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Привет!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Продолжай тренироваться")
                    .foregroundColor(.secondary)
            }

            Spacer()

            if userStats.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(userStats.streak)")
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(20)
            }
        }
    }

    private var statsSummaryView: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Тренировок",
                value: "\(userStats.history.count)",
                icon: "checkmark.circle",
                color: .blue
            )

            StatCard(
                title: "Минут",
                value: "\(Int(userStats.totalTrainingTime() / 60))",
                icon: "clock",
                color: .green
            )
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Упражнения")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(ExerciseType.allCases) { exercise in
                NavigationLink(destination: exerciseDestination(for: exercise)) {
                    ExerciseCardView(
                        exercise: exercise,
                        recommendedDifficulty: userStats.recommendedDifficulty(for: exercise)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var skillsProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Развитие навыков")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 10) {
                ForEach(userStats.allSkills.prefix(4), id: \.name) { skill in
                    SkillProgressRow(name: skill.name, progress: skill.progress)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func exerciseDestination(for exercise: ExerciseType) -> some View {
        switch exercise {
        case .schulte:
            SchulteTableView()
        case .nback:
            NBackView()
        case .numbers:
            NumbersView()
        case .colors:
            ColorsView()
        }
    }
}

struct StatCard: View {
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
                .font(.title)
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

struct SkillProgressRow: View {
    let name: String
    let progress: Double

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: max(0, geo.size.width * CGFloat(progress) / 100), height: 8)
                }
            }
            .frame(width: 100, height: 8)

            Text("\(Int(progress))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }

    var progressColor: Color {
        if progress < 40 { return .red }
        if progress < 70 { return .orange }
        return .green
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .environmentObject(UserStats())
    }
}
