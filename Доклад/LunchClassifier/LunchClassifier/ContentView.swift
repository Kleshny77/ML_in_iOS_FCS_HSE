import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var classificationResult: (label: String, confidence: Float)?
    @State private var displayedCalories: Int?
    @State private var isClassifying = false
    @State private var errorMessage: String?

    private let classifier = ImageClassifier()

    private static let minFoodConfidence: Float = 0.8
    private static let knownFoodPrefixes = ["pizza", "sushi", "burger"]

    private static func isKnownFood(_ label: String) -> Bool {
        let lower = label.lowercased()
        return knownFoodPrefixes.contains { lower.hasPrefix($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    actionsSection
                    resultSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Обед")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
        }
    }

    private static let imageSize: CGFloat = 280

    private var imageSection: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.imageSize, height: Self.imageSize)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: Self.imageSize, height: Self.imageSize)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("Выберите фото еды")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionsSection: some View {
        HStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Выбрать фото", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isClassifying)

            if selectedImage != nil {
                Button {
                    selectedItem = nil
                    selectedImage = nil
                    classificationResult = nil
                    displayedCalories = nil
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isClassifying {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Определяю блюдо и калории…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            } else if let result = classificationResult {
                let isConfident = result.confidence >= Self.minFoodConfidence
                let isKnown = Self.isKnownFood(result.label)
                let showAsKnown = isConfident && isKnown

                VStack(alignment: .leading, spacing: 14) {
                    if showAsKnown {
                        Text(result.label.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.title2.weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(Int(result.confidence * 100))% уверенность")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Не уверены, что это пицца, суши или бургер")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        Text("\(Int(result.confidence * 100))% — слишком низкая уверенность или другой класс")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            if showAsKnown, let cal = displayedCalories {
                                Text("\(cal) ккал")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.primary)
                                Text("на порцию")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Text(showAsKnown ? "Добавьте CalorieClassifier.mlmodel" : "Калории не показываем для неизвестных блюд")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            await MainActor.run {
                selectedImage = nil
                classificationResult = nil
                displayedCalories = nil
            }
            return
        }
        await MainActor.run { errorMessage = nil }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    classificationResult = nil
                    displayedCalories = nil
                }
                await classify(image: image)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Не удалось загрузить изображение"
            }
        }
    }

    private func classify(image: UIImage) async {
        await MainActor.run {
            isClassifying = true
            displayedCalories = nil
        }
        guard let result = await classifier.classify(image: image) else {
            await MainActor.run {
                isClassifying = false
                errorMessage = "Модель не загружена или не распознала блюдо. Добавьте FoodClassifier.mlmodel в проект."
            }
            return
        }
        let calories = await classifier.calories(image: image)
        await MainActor.run {
            classificationResult = (result.classLabel, result.confidence)
            displayedCalories = calories
            errorMessage = nil
            isClassifying = false
        }
    }
}

#Preview {
    ContentView()
}
