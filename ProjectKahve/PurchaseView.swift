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
                        
                        Text("Get More Credits")
                            .font(ModernTheme.Typography.title)
                            .foregroundColor(ModernTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Credits Remaining: \(creditsManager.remainingCredits)")
                            .font(ModernTheme.Typography.body)
                            .foregroundColor(ModernTheme.textSecondary)
                    }
                    
                    // Products Section
                    if storeManager.isLoading {
                        LoadingView(storeManager: storeManager)
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
        case "com.vahiguner.projectkahve.credits1_new": return 1
        case "com.vahiguner.projectkahve.credits3_new": return 3
        case "com.vahiguner.projectkahve.credits10_new2": return 10
        case "com.vahiguner.projectkahve.credits50_new": return 50
        default: return 0
        }
    }
    
    private var savingsPercentage: Int? {
        let credits = getCreditsAmount()
        if credits > 1 {
            switch credits {
            case 3: return 33
            case 10: return 59
            case 50: return 63
            default: return nil
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
                // Credits Info and Tags
                HStack(alignment: .top) {
                    // Credits Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(ModernTheme.textPrimary)
                            Text("\(getCreditsAmount()) Credits")
                                .font(ModernTheme.Typography.headline)
                                .foregroundColor(ModernTheme.textPrimary)
                        }
                        
                        if let savings = savingsPercentage {
                            Text("Save \(savings)%")
                                .font(ModernTheme.Typography.caption)
                                .foregroundColor(ModernTheme.sage)
                        }
                    }
                    
                    Spacer()
                    
                    // Tags
                    if isPopular {
                        BadgeView(text: "MOST POPULAR", color: ModernTheme.sage)
                    }
                    
                    if isBestValue {
                        BadgeView(text: "BEST VALUE", color: ModernTheme.peach)
                    }
                }

                // Price
                HStack {
                    Spacer()
                    Text(product.displayPrice)
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.textPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(ModernTheme.sage.opacity(0.1))
                        )
                }
            }
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
                    .stroke(isSelected ? ModernTheme.sage : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(ModernTheme.Typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(16)
    }
}

struct LoadingView: View {
    @ObservedObject var storeManager: StoreManager
    
    var body: some View {
        VStack(spacing: 16) {
            if let error = storeManager.loadingError {
                VStack(spacing: 12) {
                    Text("Failed to load products")
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.textSecondary)
                    
                    Text(error)
                        .font(ModernTheme.Typography.caption)
                        .foregroundColor(ModernTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        storeManager.retryLoadingProducts()
                    }) {
                        Text("Retry")
                            .font(ModernTheme.Typography.body)
                            .foregroundColor(ModernTheme.sage)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ModernTheme.sage.opacity(0.1))
                            )
                    }
                }
            } else {
                ProgressView()
                    .tint(ModernTheme.sage)
                Text("Loading Products...")
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
