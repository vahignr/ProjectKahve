import Foundation
import UIKit
import SwiftUI
import AVFoundation

struct APIService {
    
    // A background task identifier to keep track of background execution
    private static var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Function to get localized system prompt
    private static func getSystemPrompt(language: String) -> String {
        switch language {
        case "en":
            return """
                You are now playing the role of a Turkish coffee fortune teller. You will be shown two photos: one of a Turkish coffee cup and one of its plate. You'll need to interpret both the patterns in the cup and on the plate. Here's what's shown to you:

                For the Coffee Cup:
                - Examine the shapes, patterns, and positions of the coffee grounds in the cup
                - Look for distinct symbols and their locations
                - Consider the density and distribution of the grounds

                For the Plate (Saucer):
                - Study the patterns formed when the cup was turned over
                - Note any clear symbols or shapes
                - Pay attention to how the patterns spread

                Very important notes: 
                - Tell the fortune in a friendly and conversational way, as if you're talking to a close friend sitting across from you
                - Use casual language and create a natural flowing narrative without any headers, section titles, or numbered lists
                - Make the reading sound like one continuous story while covering all elements
                - Keep the total length around 750 tokens
                - Maintain proper spacing and formatting for easy reading

                Your reading should flow through these elements naturally:
                - A warm, brief introduction
                - Interpretation of 3-4 important symbols from the cup
                - Discussion of 2-3 key patterns from the plate
                - Natural connections between cup and plate symbols
                - A few realistic predictions about the person's future
                - End with an encouraging message

                Remember, the reading should be fun and interesting, but also mention things that could realistically happen. Don't make extremely exaggerated or impossible predictions, but a little embellishment is fine.
            
            """
            
        default: // Turkish
            return """
                Sen şimdi bir Türk kahvesi falı bakan kişi rolündesin. Sana iki fotoğraf gösterilecek: biri Türk kahvesi fincanı ve diğeri tabağı. Her ikisindeki telve desenlerini yorumlaman gerekiyor. İşte sana gösterilenler:

                Fincan için:
                - Fincandaki telvelerin şekillerini, desenlerini ve konumlarını incele
                - Belirgin sembolleri ve yerlerini bul
                - Telvelerin yoğunluğunu ve dağılımını değerlendir

                Tabak için:
                - Fincan çevrildiğinde oluşan desenleri incele
                - Net sembolleri ve şekilleri not et
                - Desenlerin nasıl yayıldığına dikkat et

                Çok önemli noktalar:
                - Falı, sanki karşında oturan yakın bir arkadaşınla sohbet ediyormuş gibi samimi ve doğal bir şekilde anlat
                - Günlük konuşma dilini kullan ve başlık, bölüm adı veya numaralı liste kullanmadan akıcı bir anlatım oluştur
                - Tüm elementleri kapsarken kesintisiz, tek bir hikaye gibi anlat
                - Toplam uzunluğu yaklaşık 750 token civarında tut
                - Kolay okunabilir, düzgün bir metin formatı kullan

                Falın şu öğeleri doğal bir şekilde içermeli:
                - Sıcak, kısa bir giriş
                - Fincandan 3-4 önemli sembolün yorumu
                - Tabaktan 2-3 ana desenin anlatımı
                - Fincan ve tabaktaki sembollerin doğal bağlantıları
                - Geleceğe dair birkaç gerçekçi tahmin
                - Cesaretlendirici bir kapanış mesajı

                Unutma, falın eğlenceli ve ilgi çekici olması önemli, ama aynı zamanda gerçekçi olabilecek şeylerden bahset. Çok abartılı veya imkansız şeyler söyleme, ama birazcık abartmanda herhangi bir sorun yok.
            """
        }
    }
    
    // Function to send both images to LLM API
    static func sendImageToAPI(cupImage: UIImage, plateImage: UIImage, completion: @escaping (String?) -> Void) {
        
        // *** BEGIN BACKGROUND TASK ***
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "KahveImageAPI") {
            // iOS will call this block if your background time is expiring
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        let maxSize = CGSize(width: 400, height: 400)

        guard let resizedCupImage = Utils.resizeImage(image: cupImage, maxSize: maxSize),
              let resizedPlateImage = Utils.resizeImage(image: plateImage, maxSize: maxSize),
              let base64CupImage = Utils.encodeImageToBase64(image: resizedCupImage),
              let base64PlateImage = Utils.encodeImageToBase64(image: resizedPlateImage) else {
            completion(nil)
            // End background task if images are invalid
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            return
        }

        let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Utils.getAPIKey())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let currentLanguage = LocalizationManager.shared.currentLanguage
        let systemPrompt = getSystemPrompt(language: currentLanguage)

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Here are the two images. First is the coffee cup: data:image/jpeg;base64,\(base64CupImage)"],
            ["role": "user", "content": "And here is the coffee plate: data:image/jpeg;base64,\(base64PlateImage)"]
        ]

        let jsonPayload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 750,
            "temperature": 0.5
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: jsonPayload) else {
            completion(nil)
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            return
        }

        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                // Always end background task
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("HTTP Response Body: \(String(data: data ?? Data(), encoding: .utf8) ?? "no data")")
                }
            }

            guard let data = data, let jsonString = String(data: data, encoding: .utf8) else {
                print("No data received or data could not be encoded")
                completion(nil)
                return
            }
            
            print("Raw API Response: \(jsonString)")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    print("Failed to extract content from response")
                    completion(nil)
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    // Text-to-speech function with improved error handling
    static func textToSpeech(caption: String, completion: @escaping (URL?) -> Void) {
        
        // *** BEGIN BACKGROUND TASK ***
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "KahveTTSTask") {
            // iOS will call this block if your background time is expiring
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // First, configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            // End background task if audio session fails
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            completion(nil)
            return
        }
        
        let processedCaption = processForTTS(caption)
        print("Processed caption length: \(processedCaption.count)")
        
        let apiUrlString = "https://api.openai.com/v1/audio/speech"
        guard let apiUrl = URL(string: apiUrlString) else {
            print("Invalid URL")
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Utils.getAPIKey())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let voice = currentLanguage == "en" ? "nova" : "shimmer"
        
        let requestBody: [String: Any] = [
            "model": "tts-1-hd",
            "voice": voice,
            "input": processedCaption,
            "speed": 1.0,
            "output_format": "mp3"
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to create request body")
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            completion(nil)
            return
        }
        
        request.httpBody = httpBody
        print("Sending TTS request with text length: \(processedCaption.count)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                // Always end the background task
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            if let error = error {
                print("TTS API Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("TTS HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("TTS Error Response: \(errorString)")
                    }
                    completion(nil)
                    return
                }
            }
            
            guard let data = data else {
                print("No data received from TTS API")
                completion(nil)
                return
            }
            
            let fileUrl = FileManager.default.temporaryDirectory
                .appendingPathComponent("tts_output_\(UUID().uuidString).mp3")
            
            do {
                try data.write(to: fileUrl)
                print("Audio file saved successfully at: \(fileUrl.path)")
                print("Audio file size: \(data.count) bytes")
                completion(fileUrl)
            } catch {
                print("Failed to save audio file: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private static func processForTTS(_ text: String) -> String {
        // Remove Markdown formatting
        var processedText = text.replacingOccurrences(of: "###", with: "")
        processedText = processedText.replacingOccurrences(of: "**", with: "")
        processedText = processedText.replacingOccurrences(of: "#", with: "")
        
        // Remove excess whitespace and newlines
        processedText = processedText.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ". ")
        
        // Return the full text instead of truncating it
        return processedText
    }
}
