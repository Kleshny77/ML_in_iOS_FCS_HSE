//
//  PhotoImportView.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import SwiftUI
import Vision
import VisionKit

struct PhotoImportView: UIViewControllerRepresentable {
    @Binding var importedText: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: PhotoImportView

        init(_ parent: PhotoImportView) {
            self.parent = parent
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.isPresented = false
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            Task {
                let text = await recognizeText(from: scan)
                await MainActor.run {
                    parent.importedText = text
                    parent.isPresented = false
                }
            }
        }

        private func recognizeText(from scan: VNDocumentCameraScan) async -> String {
            var extracted = ""

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                guard let cgImage = image.cgImage else { continue }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    for observation in observations {
                        if let candidate = observation.topCandidates(1).first {
                            extracted.append(candidate.string)
                            extracted.append("\n")
                        }
                    }
                } catch {
                    continue
                }
            }

            return extracted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
