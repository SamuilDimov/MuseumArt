import SwiftUI

struct ScannedImage: View {
    var recognizedText: String

    var body: some View {
        Text(recognizedText)
    }
}

struct ScannedImage_Previews: PreviewProvider {
    static var previews: some View {
        ScannedImage(recognizedText: "Example Text")
    }
}
