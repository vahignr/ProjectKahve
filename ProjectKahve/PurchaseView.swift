import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var creditsManager: CreditsManager
    @StateObject private var storeManager = StoreManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAnimation = false
    @State private var appearScale: CGFloat = 0.95
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Animated Background
            BackgroundView(animate: true)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Animated Icon
                        ZStack {
                            Circle()
                                .fill(ModernTheme.sage.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 30))
                                .foregroundColor(ModernTheme.sage)
                                .rotationEffect(.degrees(showAnimation ? 360 : 0))
                        }
                        .padding(.top, 40)
                        
                        Text("credit_pack_title".localized)
                            .font(ModernTheme.Typography.title)
                            .foregroundColor(ModernTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(String(format: "credits_remaining".localized, creditsManager.remainingCredits))
                            .font(ModernTheme.Typography.body)
                            .foregroundColor(ModernTheme.textSecondary)
                    }
                    
                    // Products Section
                    if storeManager.products.isEmpty {
                        LoadingView()
                    } else {
                        ProductsGridView(storeManager: storeManager)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            // Dismiss Button
            VStack {
                Spacer()
                DismissButton(action: { dismiss() })
            }
            .padding(.bottom, 30)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await storeManager.loadProducts()
        }
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                showAnimation = true
            }
        }
    }
}

// MARK: - Supporting Views
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(ModernTheme.sage)
            Text("loading_products".localized)
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ProductsGridView: View {
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(storeManager.products) { product in
                PurchaseButton(product: product, isSelected: selectedProduct?.id == product.id) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedProduct = product
                    }
                    Task {
                        do {
                            try await storeManager.purchase(product)
                            dismiss()
                        } catch {
                            selectedProduct = nil
                            // Handle error
                        }
                    }
                }
            }
        }
    }
}

struct PurchaseButton: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    private func getCreditsAmount() -> Int {
        switch product.id {
        case "com.vahiguner.projectkahve.credits1": return 1
        case "com.vahiguner.projectkahve.credits3": return 3
        case "com.vahiguner.projectkahve.credits10": return 10
        case "com.vahiguner.projectkahve.credits50": return 50
        default: return 0
        }
    }
    
    private var savings: String? {
        let credits = getCreditsAmount()
        if credits > 1 {
            let singleCreditPrice = 0.49
            let totalWithoutDiscount = singleCreditPrice * Double(credits)
            let productPrice = (product.price as NSDecimalNumber).doubleValue
            let savings = totalWithoutDiscount - productPrice
            if savings > 0.01 { // Only show if savings are significant
                return String(format: "Save %.0f%%", (savings/totalWithoutDiscount) * 100)
            }
        }
        return nil
    }
    
    private var isPopular: Bool {
        return getCreditsAmount() == 10
    }
    
    private var isBestValue: Bool {
        return getCreditsAmount() == 50
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Tags Section
                HStack {
                    if isPopular {
                        TagView(text: "MOST POPULAR", color: ModernTheme.sage)
                    }
                    if isBestValue {
                        TagView(text: "BEST VALUE", color: ModernTheme.peach)
                    }
                    Spacer()
                }
                .padding(.bottom, isPopular || isBestValue ? 8 : 0)
                
                // Credits and Price
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                            Text("\(getCreditsAmount()) Credits")
                                .font(ModernTheme.Typography.headline)
                        }
                        
                        if let savingsText = savings {
                            Text(savingsText)
                                .font(ModernTheme.Typography.caption)
                                .foregroundColor(ModernTheme.sage)
                        }
                    }
                    
                    Spacer()
                    
                    Text(product.displayPrice)
                        .font(ModernTheme.Typography.body)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(ModernTheme.sage.opacity(0.1))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ModernTheme.surface)
                    .shadow(
                        color: isSelected ? ModernTheme.sage.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 20 : 10,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? ModernTheme.sage : Color.clear,
                        lineWidth: 2
                    )
            )
            .foregroundColor(ModernTheme.textPrimary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

struct DismissButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(ModernTheme.sage.opacity(0.7))
                .background(Circle().fill(ModernTheme.surface))
                .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
    }
}

#Preview {
    PurchaseView()
        .environmentObject(CreditsManager.shared)
}
