//
//  PhotoPickerView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import SwiftUI
import PhotosUI
import Vision

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var importedText: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.isPresented = false
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let image = object as? UIImage, let cgImage = image.cgImage else {
                        DispatchQueue.main.async { self.parent.isPresented = false }
                        return
                    }

                    Task {
                        let text = await self.recognizeText(from: cgImage)
                        await MainActor.run {
                            self.parent.importedText = text
                            self.parent.isPresented = false
                        }
                    }
                }
            } else {
                parent.isPresented = false
            }
        }

        private func recognizeText(from cgImage: CGImage) async -> String {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                return strings.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                return ""
            }
        }
    }
}
