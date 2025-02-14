import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "APILanguage")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            Bundle.setLanguage(currentLanguage)
        }
    }
    
    static let shared = LocalizationManager()
    
    private init() {
        // First, try to get the stored API language
        if let storedLanguage = UserDefaults.standard.string(forKey: "APILanguage") {
            self.currentLanguage = storedLanguage
        } else {
            // If no stored language, set based on device region
            let deviceRegion = Locale.current.regionCode ?? "US"
            self.currentLanguage = deviceRegion == "TR" ? "tr" : "en"
            
            // Store the initial language
            UserDefaults.standard.set(self.currentLanguage, forKey: "APILanguage")
            UserDefaults.standard.set([self.currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
        
        // Initialize the bundle
        Bundle.setLanguage(self.currentLanguage)
    }
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
    
    func getCurrentAPILanguage() -> String {
        return currentLanguage
    }
}

// MARK: - Bundle Extension
extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        Bundle.bundle = nil
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            Bundle.bundle = bundle
        }
    }
    
    static func localizedBundle() -> Bundle {
        return Bundle.bundle ?? Bundle.main
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: Bundle.localizedBundle(), comment: "")
    }
}
