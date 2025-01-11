import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    // Product IDs for each credit pack
    private let productIdentifiers = [
        "com.vahiguner.projectkahve.credits1",  // 1 Credit - $0.49
        "com.vahiguner.projectkahve.credits3",  // 3 Credits - $0.99
        "com.vahiguner.projectkahve.credits10", // 10 Credits - $1.99
        "com.vahiguner.projectkahve.credits50"  // 50 Credits - $8.99
    ]
    
    private init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
            // Sort products by price
            products.sort { $0.price < $1.price }
            print("Products loaded successfully: \(products.count) products")
            // Debug: Print each product
            for product in products {
                print("Product ID: \(product.id), Price: \(product.price)")
            }
        } catch {
            print("Failed to load products:", error)
        }
    }
    
    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                // Add appropriate number of credits based on product ID
                let credits = creditsForProduct(product.id)
                CreditsManager.shared.addCredits(credits)
                await transaction.finish()
                print("Purchase successful! Added \(credits) credits")
            case .unverified(_, let error):
                throw error
            }
        case .userCancelled:
            print("User cancelled the purchase")
        case .pending:
            print("Purchase pending")
        @unknown default:
            break
        }
    }
    
    private func creditsForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.vahiguner.projectkahve.credits1":
            return 1
        case "com.vahiguner.projectkahve.credits3":
            return 3
        case "com.vahiguner.projectkahve.credits10":
            return 10
        case "com.vahiguner.projectkahve.credits50":
            return 50
        default:
            return 0
        }
    }
}
