import SwiftUI

struct CreditsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var creditsManager: CreditsManager
    @State private var appearScale: CGFloat = 0.95
    @State private var appearOpacity: Double = 0
    @State private var showPurchaseView = false
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView(animate: true)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(ModernTheme.sage.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundColor(ModernTheme.sage)
                            .symbolEffect(.bounce, options: .repeating)
                    }
                    .padding(.top, 40)
                    
                    Text("your_credits".localized)
                        .font(ModernTheme.Typography.title)
                        .foregroundColor(ModernTheme.textPrimary)
                    
                    // Credits Display
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                        Text("\(creditsManager.remainingCredits)")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .foregroundColor(ModernTheme.sage)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ModernTheme.sage.opacity(0.1))
                    )
                    
                    Text("credits_remaining_desc".localized)
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Buy Credits Button
                Button(action: { showPurchaseView = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("buy_credits".localized)
                            .font(ModernTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ModernTheme.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: ModernTheme.sage.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Dismiss Button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ModernTheme.sage.opacity(0.7))
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
    }
}

#Preview {
    CreditsDetailView()
        .environmentObject(CreditsManager.shared)
}
