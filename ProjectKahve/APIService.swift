import Foundation
import UIKit
import AVFoundation

struct APIService {
    
    // A background task identifier to keep track of background execution
    private static var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Prompt Definitions
    
    // Dream Interpretation Prompts
    private static let enDreamPrompt = """
    You are now playing the role of a skilled dream interpreter with deep knowledge of both modern psychology and traditional dream interpretation methods.
    
    Guidelines for interpretation:
    - Begin with a warm, engaging greeting
    - Analyze the key symbols and themes in the dream
    - Provide both psychological and traditional interpretations
    - Connect the dream's meaning to the dreamer's possible life situations
    - Offer gentle guidance or insights based on the interpretation
    - End with an encouraging message
    
    Keep the interpretation:
    - Personal and conversational in tone
    - Around 750 tokens in length
    - Free from technical jargon
    - Structured as a flowing narrative
    - Balanced between practical insight and mystical wisdom
    
    The dream to interpret is:
    """
    
    private static let trDreamPrompt = """
    Şu anda hem modern psikoloji hem de geleneksel rüya yorumlama yöntemlerinde derin bilgi sahibi, yetenekli bir rüya yorumcusu rolündesin.
    
    Yorumlama kuralları:
    - Sıcak ve samimi bir selamlama ile başla
    - Rüyadaki ana sembolleri ve temaları analiz et
    - Hem psikolojik hem de geleneksel yorumlar sun
    - Rüyanın anlamını kişinin olası yaşam durumlarıyla ilişkilendir
    - Yoruma dayalı nazik rehberlik ve içgörüler öner
    - Cesaretlendirici bir mesajla bitir
    
    Yorumun şu özelliklere sahip olmalı:
    - Kişisel ve sohbet tarzında
    - Yaklaşık 750 token uzunluğunda
    - Teknik terimlerden arınmış
    - Akıcı bir anlatı şeklinde
    - Pratik içgörü ve mistik bilgelik arasında dengeli
    
    Yorumlanacak rüya:
    """
    
    // 1) Cup + Plate (English)
    private static let enCupPlatePrompt = """
    You are now playing the role of a Turkish coffee fortune teller.
    
    
    For the Coffee Cup:
    - Examine the shapes, patterns, and positions of the coffee grounds in the cup
    - Look for distinct symbols and their locations
    - Consider the density and distribution of the grounds
    
    For the Plate (Saucer):
    - Study the patterns formed when the cup was turned over
    - Note any clear symbols or shapes
    - Pay attention to how the patterns spread
    
    Very important notes:
    - Tell the fortune in a friendly and conversational way, as if you're talking to a close friend
    - Use casual language and create a natural flowing narrative without any headers or numbered lists
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
    
    // 2) Cup + Plate (Turkish)
    private static let trCupPlatePrompt = """
    Sen şimdi bir Türk kahvesi falı bakan kişi rolündesin.

    
    Fincan için:
    - Fincandaki telvelerin şekillerini, desenlerini ve konumlarını incele
    - Belirgin sembolleri ve yerlerini bul
    - Telvelerin yoğunluğunu ve dağılımını değerlendir
    
    Tabak için:
    - Fincan çevrildiğinde oluşan desenleri incele
    - Net sembolleri ve şekilleri not et
    - Desenlerin nasıl yayıldığına dikkat et
    
    Çok önemli noktalar:
    - Falı, sanki karşında oturan yakın bir arkadaşınla sohbet ediyormuş gibi samimi bir şekilde anlat
    - Başlık, bölüm adı veya numaralı liste kullanmadan akıcı bir dil kullan
    - Anlatım tek bir hikaye gibi olsun ve tüm öğeleri kapsasın
    - Toplam uzunluğu yaklaşık 750 token civarında tut
    - Okunaklı bir metin formatı kullan
    
    Falın doğal akışı şunları içermeli:
    - Sıcak, kısa bir giriş
    - Fincandan 3-4 önemli sembol yorumu
    - Tabaktan 2-3 ana desenin anlatımı
    - Fincan ve tabaktaki sembollerin bağlantıları
    - Geleceğe dair birkaç gerçekçi tahmin
    - Cesaretlendirici bir kapanış
    
    Fal eğlenceli ve ilgi çekici olmalı ancak gerçekçi şeylerden bahset. Çok uçuk veya imkansız tahminlerden kaçın, ama biraz abartabilirsin.
    """
    
    // 3) Cup-Only (English)
    private static let enCupOnlyPrompt = """
    You are now playing the role of a Turkish coffee fortune teller.
    
    IMPORTANT RULE:
    - Focus only on reading the coffee cup
    
    For the Coffee Cup:
    - Examine the shapes, patterns, and positions of the coffee grounds in the cup
    - Look for distinct symbols and their locations
    - Consider the density and distribution of the grounds
    
    Very important notes:
    - Tell the fortune in a friendly and conversational way, as if you're talking to a close friend
    - Use casual language and create a natural flowing narrative without any headers or numbered lists
    - Make the reading sound like one continuous story while covering all elements
    - Keep the total length around 750 tokens
    - Maintain proper spacing and formatting for easy reading
    
    Your reading should flow through these elements naturally:
    - A warm, brief introduction
    - Interpretation of 4-5 important symbols from the cup
    - Natural connections between the symbols
    - A few realistic predictions about the person's future
    - End with an encouraging message
    
    Remember, the reading should be fun and interesting, but also mention things that could realistically happen. Don't make extremely exaggerated or impossible predictions, but a little embellishment is fine.
    """
    
    // 4) Cup-Only (Turkish)
    private static let trCupOnlyPrompt = """
    Sen şimdi bir Türk kahvesi falı bakan kişi rolündesin.
    
    Önemli Kural:
    - Sadece fincan falı bak
    
    Fincan için:
    - Fincandaki telvelerin şekillerini, desenlerini ve konumlarını incele
    - Belirgin sembolleri ve yerlerini bul
    - Telvelerin yoğunluğunu ve dağılımını değerlendir
    
    Çok önemli noktalar:
    - Falı, sanki karşında oturan yakın bir arkadaşınla sohbet ediyormuş gibi samimi bir şekilde anlat
    - Başlık, bölüm adı veya numaralı liste kullanmadan akıcı bir dil kullan
    - Anlatım tek bir hikaye gibi olsun ve tüm öğeleri kapsasın
    - Toplam uzunluğu yaklaşık 750 token civarında tut
    - Okunaklı bir metin formatı kullan
    
    Falın doğal akışı şunları içermeli:
    - Sıcak, kısa bir giriş
    - Fincandan 4-5 önemli sembol yorumu
    - Sembollerin birbiriyle bağlantıları
    - Geleceğe dair birkaç gerçekçi tahmin
    - Cesaretlendirici bir kapanış
    
    Fal eğlenceli ve ilgi çekici olmalı ancak gerçekçi şeylerden bahset. Çok uçuk veya imkansız tahminlerden kaçın, ama biraz abartabilirsin.
    """
    
    // MARK: - Helper: Determine which prompt to use
        private static func getSystemPrompt(language: String, isCupOnly: Bool) -> String {
            if language == "en" {
                return isCupOnly ? enCupOnlyPrompt : enCupPlatePrompt
            } else {
                // default to Turkish
                return isCupOnly ? trCupOnlyPrompt : trCupPlatePrompt
            }
        }
        
        // MARK: - Dream Interpretation API
        static func sendDreamToAPI(dreamText: String, completion: @escaping (String?) -> Void) {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "DreamAPI") {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            let currentLanguage = LocalizationManager.shared.getCurrentAPILanguage()
            let systemPrompt = currentLanguage == "en" ? enDreamPrompt : trDreamPrompt
            
            let messages: [[String: String]] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": dreamText]
            ]
            
            let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(Utils.getAPIKey())", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonPayload: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": messages,
                "max_tokens": 750,
                "temperature": 0.7
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
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    backgroundTaskID = .invalid
                }
                
                if let error = error {
                    print("Network Error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    print("Failed to parse API response")
                    completion(nil)
                    return
                }
                
                completion(content)
            }
            task.resume()
        }
        
        // MARK: - Send Image to API
        static func sendImageToAPI(cupImage: UIImage, plateImage: UIImage?, completion: @escaping (String?) -> Void) {
            // *** BEGIN BACKGROUND TASK ***
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "KahveImageAPI") {
                // iOS will call this block if your background time is expiring
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
            
            let maxSize = CGSize(width: 400, height: 400)
            
            // Resize and encode cup image
            guard let resizedCupImage = Utils.resizeImage(image: cupImage, maxSize: maxSize),
                  let base64CupImage = Utils.encodeImageToBase64(image: resizedCupImage) else {
                completion(nil)
                // End background task if images are invalid
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
                return
            }
            
            // If plateImage is not nil, resize and encode it; otherwise, skip
            var base64PlateImage: String? = nil
            if let plate = plateImage {
                if let resizedPlate = Utils.resizeImage(image: plate, maxSize: maxSize),
                   let encodedPlate = Utils.encodeImageToBase64(image: resizedPlate) {
                    base64PlateImage = encodedPlate
                }
            }
            
            // Decide which prompt to use
            let currentLanguage = LocalizationManager.shared.getCurrentAPILanguage()
            let isCupOnly = (base64PlateImage == nil)  // if no plate image, it's cup-only reading
            let systemPrompt = getSystemPrompt(language: currentLanguage, isCupOnly: isCupOnly)
            
            // Prepare the messages array
            var messages: [[String: String]] = [
                ["role": "system", "content": systemPrompt]
            ]
            
            // Add the cup image
            messages.append(["role": "user", "content": "Here is the coffee cup: data:image/jpeg;base64,\(base64CupImage)"])
            
            // If there's a plate image, add it
            if let validPlate = base64PlateImage {
                messages.append(["role": "user", "content": "Here is the coffee plate: data:image/jpeg;base64,\(validPlate)"])
            }
            
            // Prepare request
            let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(Utils.getAPIKey())", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
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
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    print("Failed to parse API response")
                    completion(nil)
                    return
                }
                
                completion(content)
            }
            task.resume()
        }
        
        // MARK: - Text-to-speech function
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
            
            let currentLanguage = LocalizationManager.shared.getCurrentAPILanguage()
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
            
            return processedText
        }
    }
