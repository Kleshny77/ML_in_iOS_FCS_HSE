import SwiftUI

struct ExerciseInfoSheet: View {
    let exercise: ExerciseType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 60, height: 60)

                            Image(systemName: exercise.icon)
                                .font(.title)
                                .foregroundColor(.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(exercise.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    MarkdownText(content: exercise.detailedInstructions)
                        .lineSpacing(4)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Развиваемые навыки:")
                            .font(.headline)
                            .padding(.horizontal)

                        FlowLayout(spacing: 8) {
                            ForEach(exercise.targetSkills, id: \.self) { skill in
                                Text(skill)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)

                    Button(action: { dismiss() }) {
                        Text("Понятно!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseInfoSheet_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseInfoSheet(exercise: .schulte)
    }
}
