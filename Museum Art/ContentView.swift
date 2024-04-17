import SwiftUI
import UIKit
import AVFoundation
import Vision

//// Extension to handle hexadecimal colors in SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

struct ContentView: View {
    @State private var recognizedArtworkIdentifier: String? = nil
    @State private var displayedText: String = "Capture an image to recognize"
    @State private var isScanning: Bool = false
    @State private var showImagePicker = false
    @State private var isSpeaking: Bool = false
    @State private var image: UIImage?
    let artworkDescriptions: [String: ArtworkDescription] = loadArtworkDescriptions()
    let synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
       
            NavigationStack {
                VStack {
                    
                    if isScanning {
                        if let image = image {
                            VStack { 
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                            .padding()
                            .background(Color(hex: "242223")) // Optional: background color for image container
                            .cornerRadius(20)
                            .foregroundColor(Color(hex: "F5F5DC"))
                        
                            Text(displayedText)
                                .padding()
                                .foregroundColor(Color(hex: "F5F5DC"))
                                
                            HStack {
                                if let identifier = recognizedArtworkIdentifier,
                                   let description = artworkDescriptions[identifier]?.description {
                                    Button(isSpeaking ? "Stop" : "Read Description") {
                                        if isSpeaking {
                                            stopSpeaking()
                                        } else {
                                            speak(description)
                                        }
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "F1ECDD"))
                                    .foregroundColor(Color(hex: "242223"))
                                    .cornerRadius(100)
                                }
                                Button("Scan New Image") {
                                    self.image = nil
                                    self.recognizedArtworkIdentifier = nil
                                    self.displayedText = "Capture an image to recognize"
                                    self.showImagePicker = true
                                    if isSpeaking {
                                        stopSpeaking()
                                    }
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .foregroundColor(Color(hex: "242223"))
                                .padding()
                                .background(Color(hex: "FFD700"))
                                .cornerRadius(100)
                            }
                            .padding()
                        } else {
                            Button("Take Picture") {
                                showImagePicker = true
                            }
                            .font(.title)
                            .foregroundColor(Color(hex: "242223"))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FFD700"))
                            .cornerRadius(100)
                            .padding()
                        }
                    } else {
                        Button("Scan") {
                            isScanning = true
                        }
                        .font(.title)
                        .foregroundColor(Color(hex: "242223"))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FFD700"))
                        .cornerRadius(100)
                        .padding()
                    }
                }
                .sheet(isPresented: $showImagePicker, onDismiss: processImage) {
                    ImagePicker(image: $image, sourceType: .camera)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }

    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
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
                self.recognizedArtworkIdentifier = topResult.identifier
                if let recognizedArtwork = self.artworkDescriptions[topResult.identifier] {
                    self.displayedText = "\(recognizedArtwork.title): \(recognizedArtwork.description)"
                } else {
                    self.displayedText = "Artwork not recognized"
                }
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    func speak(_ text: String) {
        DispatchQueue.main.async {
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            self.synthesizer.speak(utterance)
            self.isSpeaking = true
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ArtworkDescription: Codable {
    let identifier: String
    let title: String
    let description: String
}

struct ArtworkDescriptions: Codable {
    let artworks: [ArtworkDescription]
}

func loadArtworkDescriptions() -> [String: ArtworkDescription] {
    guard let url = Bundle.main.url(forResource: "artDescription", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load artDescription.json from bundle.")
    }
    
    let decoder = JSONDecoder()
    guard let loadedArtworks = try? decoder.decode(ArtworkDescriptions.self, from: data) else {
        fatalError("Failed to decode artDescription.json.")
    }

    return Dictionary(uniqueKeysWithValues: loadedArtworks.artworks.map { ($0.identifier, $0) })
}

