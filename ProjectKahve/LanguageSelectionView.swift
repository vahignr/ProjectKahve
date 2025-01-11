import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedLanguage: String = LocalizationManager.shared.currentLanguage
    @State private var appearScale: CGFloat = 0.95
    @State private var appearOpacity: Double = 0
    
    private let languages = [
        ("English", "en", "🇺🇸"),
        ("Türkçe", "tr", "🇹🇷")
    ]
    
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
                        
                        Image(systemName: "globe")
                            .font(.system(size: 30))
                            .foregroundColor(ModernTheme.sage)
                    }
                    .padding(.top, 40)
                    
                    Text("select_language".localized)
                        .font(ModernTheme.Typography.title)
                        .foregroundColor(ModernTheme.textPrimary)
                    
                    Text("choose_preferred_language".localized)
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Language Options
                VStack(spacing: 16) {
                    ForEach(languages, id: \.1) { name, code, flag in
                        LanguageButton(
                            title: name,
                            flag: flag,
                            isSelected: selectedLanguage == code
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedLanguage = code
                                localizationManager.setLanguage(code)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
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

struct LanguageButton: View {
    let title: String
    let flag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(ModernTheme.Typography.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ModernTheme.sage)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
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
        }
        .buttonStyle(ScaleButtonStyle())
        .foregroundColor(ModernTheme.textPrimary)
    }
}

#Preview {
    LanguageSelectionView()
}
