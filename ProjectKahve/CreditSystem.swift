import Foundation
import SwiftUI

// Optional: If you still want your "CreditPack" struct for display purposes
struct CreditPack: Identifiable {
    let id = UUID()
    let credits: Int
    let price: Double
    let currency: String
    
    var formattedPrice: String {
        String(format: "%.2f %@", price, currency)
    }
    
    var displayTitle: String {
        "\(credits) Credits"
    }
}

final class CreditsManager: ObservableObject {
    @Published private(set) var remainingCredits: Int
    static let shared = CreditsManager()
    
    private init() {
        // Check if the app has launched before by looking up a flag in UserDefaults
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // First launch: Give one free credit to the new user
            remainingCredits = 1
            // Mark that the app has now launched and save the free credit count
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.set(1, forKey: "remainingCredits")
        } else {
            // Not the first launch: Load saved credit count
            let savedCredits = UserDefaults.standard.integer(forKey: "remainingCredits")
            remainingCredits = savedCredits
        }
    }
    
    func useCredit() -> Bool {
        guard remainingCredits > 0 else { return false }
        remainingCredits -= 1
        UserDefaults.standard.set(remainingCredits, forKey: "remainingCredits")
        return true
    }
    
    func addCredits(_ amount: Int) {
        remainingCredits += amount
        UserDefaults.standard.set(remainingCredits, forKey: "remainingCredits")
    }
}
