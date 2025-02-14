import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: String?
    
    // Product IDs for each credit pack
    private let productIdentifiers = Set([
        "com.vahiguner.projectkahve.credits1_new",
        "com.vahiguner.projectkahve.credits3_new",
        "com.vahiguner.projectkahve.credits10_new2",
        "com.vahiguner.projectkahve.credits50_new"
    ])
    
    private init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        loadingError = nil
        
        do {
            print("🔄 Starting to load products...")
            print("📦 Product IDs to fetch: \(productIdentifiers)")
            
            // Request products from App Store
            let storeProducts = try await Product.products(for: productIdentifiers)
            
            print("✅ Raw response received from Store")
            print("📊 Number of products received: \(storeProducts.count)")
            
            // Log each product's details
            storeProducts.forEach { product in
                print("""
                    Product Details:
                    - ID: \(product.id)
                    - Price: \(product.price)
                    - Display Name: \(product.displayName)
                    - Description: \(product.description)
                    ------------------
                    """)
            }
            
            // Verify we got products back
            guard !storeProducts.isEmpty else {
                print("❌ No products returned from the Store")
                loadingError = """
                    No products available. 
                    This might be because:
                    - Products are not yet approved in App Store Connect
                    - Product IDs don't match
                    - In-App Purchases are not properly configured
                    """
                isLoading = false
                return
            }
            
            // Sort products by price
            products = storeProducts.sorted { $0.price < $1.price }
            print("✅ Successfully loaded and sorted \(products.count) products")
            
        } catch let error as SKError {
            print("❌ SKError: \(error.localizedDescription)")
            handleSKError(error)
        } catch {
            print("❌ General Error: \(error.localizedDescription)")
            loadingError = """
                Failed to load products: \(error.localizedDescription)
                Please check your internet connection and try again.
                """
        }
        
        isLoading = false
    }
    
    private func handleSKError(_ error: SKError) {
        let errorMessage: String
        switch error.code {
        case .unknown:
            errorMessage = "Unknown error. Please try again."
        case .clientInvalid:
            errorMessage = "Client is not allowed to make the request."
        case .paymentCancelled:
            errorMessage = "Payment was cancelled."
        case .paymentInvalid:
            errorMessage = "Invalid payment."
        case .paymentNotAllowed:
            errorMessage = "Payment not allowed."
        case .storeProductNotAvailable:
            errorMessage = "Products not available in the current storefront."
        case .cloudServicePermissionDenied:
            errorMessage = "Cloud service permission denied."
        case .cloudServiceNetworkConnectionFailed:
            errorMessage = "Network connection failed."
        case .cloudServiceRevoked:
            errorMessage = "Cloud service revoked."
        default:
            errorMessage = "An error occurred. Please try again."
        }
        loadingError = errorMessage
        print("🚨 StoreKit Error: \(errorMessage)")
    }
    
    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        
        do {
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
                print("Unknown purchase result")
            }
        } catch {
            print("Purchase failed:", error.localizedDescription)
            throw error
        }
        
        purchaseInProgress = false
    }
    
    private func creditsForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.vahiguner.projectkahve.credits1_new": return 1
        case "com.vahiguner.projectkahve.credits3_new": return 3
        case "com.vahiguner.projectkahve.credits10_new2": return 10
        case "com.vahiguner.projectkahve.credits50_new": return 50
        default: return 0
        }
    }
    
    func retryLoadingProducts() {
        Task {
            await loadProducts()
        }
    }
}
