import SwiftUI
import UIKit
import AVFoundation
import Vision

struct ContentView: View {
    @State private var recognizedText: String = "Capture an image to recognize"
    @State private var isScanning: Bool = false
    @State private var showImagePicker = false
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack {
                if isScanning {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        Text(recognizedText)
                            .padding()
                        Button("Scan New Image") {
                            self.image = nil
                            self.recognizedText = "Capture an image to recognize"
                            self.showImagePicker = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                        .padding()
                    } else {
                        Button("Take Picture") {
                            showImagePicker = true
                        }
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding()
                    }
                } else {
                    Button("Scan") {
                        isScanning = true
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
                }
            }
            .sheet(isPresented: $showImagePicker, onDismiss: processImage) {
                ImagePicker(image: $image, sourceType: .camera)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func processImage() {
        guard let image = image else { return }
        recognizeImage(image)
    }

    private func recognizeImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        guard let model = try? VNCoreMLModel(for: ArtClassifier(configuration: MLModelConfiguration()).model) else { return }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else { return }

            DispatchQueue.main.async {
                self.recognizedText = topResult.identifier
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
