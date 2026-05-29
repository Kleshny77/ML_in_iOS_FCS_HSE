import SwiftUI

struct ExerciseCardView: View {
    let exercise: ExerciseType
    let recommendedDifficulty: DifficultyLevel

    var body: some View {
        HStack(spacing: 16) {

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: exercise.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.headline)

                Text(exercise.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    ForEach(exercise.targetSkills.prefix(2), id: \.self) { skill in
                        Text(skill)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: difficultyIcon)
                    .foregroundColor(difficultyColor)
                Text("Ур. \(recommendedDifficulty.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    var difficultyIcon: String {
        switch recommendedDifficulty.rawValue {
        case 1...3: return "star"
        case 4...6: return "star.fill"
        case 7...8: return "flame.fill"
        default: return "star"
        }
    }

    var difficultyColor: Color {
        switch recommendedDifficulty.rawValue {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .gray
        }
    }
}

struct ExerciseCardView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseCardView(exercise: .schulte, recommendedDifficulty: .level1)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
