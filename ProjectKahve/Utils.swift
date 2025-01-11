import Foundation
import UIKit
import AVFoundation

struct Utils {
    // Function to resize the image to a specified maximum size
    static func resizeImage(image: UIImage, maxSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    // Function to encode an image to a Base64 string
    static func encodeImageToBase64(image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
    }

    // Function to retrieve API key from Secrets.plist
    static func getAPIKey() -> String {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let apiKey = dict["OPENAI_API_KEY"] as? String {
            return apiKey
        } else {
            fatalError("OpenAI API key not found in Secrets.plist")
        }
    }

    // Function to save audio data to a temporary file and return the file URL
    static func saveFile(data: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(UUID().uuidString + ".mp3")
        try? data.write(to: fileUrl)
        return fileUrl
    }

    static func loadAndPlayAudio(from url: URL) -> AVAudioPlayer? {
        do {
            // Reset audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Load audio data
            let audioData = try Data(contentsOf: url)
            print("Audio data size: \(audioData.count) bytes")
            
            // Create and configure player
            let player = try AVAudioPlayer(data: audioData)
            player.prepareToPlay()
            print("Audio player initialized successfully")
            return player
        } catch {
            print("Audio setup error: \(error.localizedDescription)")
            print("Error domain: \(error._domain)")
            print("Error code: \(error._code)")
            return nil
        }
    }
}
