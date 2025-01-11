import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            Bundle.setLanguage(currentLanguage)
        }
    }
    
    static let shared = LocalizationManager()
    
    init() {
        if let languageArray = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let currentLanguage = languageArray.first {
            self.currentLanguage = currentLanguage
        } else {
            self.currentLanguage = "tr" // Default to Turkish
        }
    }
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
}

// Extension for dynamic language switching
extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        Bundle.bundle = nil
        
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        if let bundle = path.map(Bundle.init(path:)) ?? nil {
            Self.bundle = bundle
        }
    }
    
    static func localizedBundle() -> Bundle {
        return Self.bundle ?? Bundle.main
    }
}

// Extension for localized string
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.localizedBundle(), value: "", comment: "")
    }
}
