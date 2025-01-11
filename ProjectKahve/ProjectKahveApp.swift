import SwiftUI

@main
struct ProjectKahveApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var creditsManager = CreditsManager.shared
    
    init() {
        if let languageCode = UserDefaults.standard.string(forKey: "AppleLanguages") {
            Bundle.setLanguage(languageCode)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            CategorySelectionView()
                .environmentObject(localizationManager)
                .environmentObject(creditsManager)
        }
    }
}
