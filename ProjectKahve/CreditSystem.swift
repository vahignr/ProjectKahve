import Foundation
import SwiftUI

struct CreditPack: Identifiable {
    let id = UUID()
    let credits: Int
    let price: Double
    let currency: String
    
    var formattedPrice: String {
        return String(format: "%.2f %@", price, currency)
    }
    
    // Helper computed property for display
    var displayTitle: String {
        return "\(credits) Credits"
    }
}

final class CreditsManager: ObservableObject {
    @Published private(set) var remainingCredits: Int
    static let shared = CreditsManager()
    
    let availablePacks: [CreditPack] = [
        CreditPack(credits: 1, price: 0.49, currency: "USD"),
        CreditPack(credits: 3, price: 0.99, currency: "USD"),
        CreditPack(credits: 10, price: 1.99, currency: "USD"),
        CreditPack(credits: 50, price: 8.99, currency: "USD")
    ]
    
    private init() {
        self.remainingCredits = UserDefaults.standard.integer(forKey: "remainingCredits")
        if self.remainingCredits == 0 {
            self.remainingCredits = 0
            UserDefaults.standard.set(0, forKey: "remainingCredits")
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
