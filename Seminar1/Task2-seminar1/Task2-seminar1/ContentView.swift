//
//  ContentView.swift
//  Task2-seminar1
//
//  Created by Artem Samsonov on 22.01.2026.
//

//
//  ContentView.swift
//  Seminar1
//
//  Created by Artem Samsonov on 16.01.2026.
//

import SwiftUI
import CoreML
import Vision
import PhotosUI

struct ContentView: View {
  
  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?
  @State private var classificationResult: String = "Выбери изображение"
  
  var body: some View {
    VStack(spacing: 20) {
      if let image = selectedImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 250)
          .cornerRadius(12)
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .frame(height: 250)
          .overlay(Text("Нет изображения"))
      }
      
      Text(classificationResult)
        .font(.headline)
        .multilineTextAlignment(.center)
      
      PhotosPicker(
        selection: $selectedItem,
        matching: .images
      ) {
        Text("Выбрать фото")
          .padding()
          .background(.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
    .padding()
    .onChange(of: selectedItem) { _, newValue in
      loadImage(from: newValue)
    }
  }
}

extension ContentView {
  
  func loadImage(from item: PhotosPickerItem?) {
    guard let item else { return }
    
    Task {
      if let data = try? await item.loadTransferable(type: Data.self),
         let uiImage = UIImage(data: data) {
        selectedImage = uiImage
        classifyImage(uiImage)
      }
    }
  }
}

extension ContentView {
  
  func classifyImage(_ image: UIImage) {
    guard let ciImage = CIImage(image: image) else {
      classificationResult = "Ошибка обработки изображения"
      return
    }
    
    do {
      let config = MLModelConfiguration()
      config.computeUnits = .all
      
      let coreMLModel = try MyImageClassifier_2(configuration: config)
      let visionModel = try VNCoreMLModel(for: coreMLModel.model)
      
      let request = VNCoreMLRequest(model: visionModel) { request, error in
        DispatchQueue.main.async {
          if let error {
            classificationResult = "Ошибка: \(error.localizedDescription)"
            return
          }
          
          guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
            classificationResult = "Ничего не распознано"
            return
          }
          
          let confidencePercent = Int(topResult.confidence * 100)
          
          if confidencePercent < 80 {
            classificationResult = "Неопознанное существо\nУверенность: \(confidencePercent)%"
          } else {
            classificationResult = "\(topResult.identifier)\nУверенность: \(confidencePercent)%"
          }
        }
      }
      
      
      let handler = VNImageRequestHandler(ciImage: ciImage)
      try handler.perform([request])
      
    } catch {
      DispatchQueue.main.async {
        classificationResult = "Ошибка модели: \(error.localizedDescription)"
      }
    }
    
  }
}

#Preview {
  ContentView()
}
