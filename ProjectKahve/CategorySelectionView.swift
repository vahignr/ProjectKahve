import SwiftUI

// MARK: - Fortune Category Model
struct FortuneCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let isAvailable: Bool
    let gradientColors: [Color]
    
    static func defaultCategories() -> [FortuneCategory] {
        [
            FortuneCategory(
                title: "coffee_fortune".localized,
                icon: "cup.and.saucer.fill",
                description: "coffee_fortune_desc".localized,
                isAvailable: true,
                gradientColors: [ModernTheme.sage, ModernTheme.mint]
            ),
            FortuneCategory(
                title: "dream_interpreter".localized,
                icon: "moon.stars.fill",
                description: "dream_interpreter_desc".localized,
                isAvailable: true,
                gradientColors: [ModernTheme.lavender, ModernTheme.sage]
            )
        ]
    }
}

// MARK: - Category Selection View
struct CategorySelectionView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showKahveFali = false
    @State private var showDreamInterpreter = false
    @State private var isLoading = true
    @State private var showLanguageSelection = false
    @State private var selectedCategory: FortuneCategory?
    @State private var animateBackground = false
    @State private var appearScale: CGFloat = 0.95
    @State private var appearOpacity: Double = 0
    
    private let categories = FortuneCategory.defaultCategories()
    
    var body: some View {
        ZStack {
            // Animated Background
            BackgroundView(animate: true)

            // Main Content
            VStack(spacing: 32) {
                // Header
                HeaderView()
                
                // Categories Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(categories) { category in
                            CategoryCard(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                                if category.isAvailable {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if category.title == "dream_interpreter".localized {
                                            showDreamInterpreter = true
                                        } else {
                                            showKahveFali = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                Spacer(minLength: 0)
            }
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
        }
        .overlay(alignment: .bottomTrailing) {
            LanguageSelectorButton(showLanguageSelection: $showLanguageSelection)
                .padding(.trailing, 24)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .fullScreenCover(isPresented: $showKahveFali) {
            ContentView()
        }
        .fullScreenCover(isPresented: $showDreamInterpreter) {
            DreamInterpreterView()
        }
        .overlay {
            if isLoading {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isLoading = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateBackground.toggle()
            }
        }
    }
}

// MARK: - Supporting Views
struct BackgroundView: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            ModernTheme.background
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(ModernTheme.peachToMint)
                        .frame(width: proxy.size.width * 0.8)
                        .offset(
                            x: -proxy.size.width * 0.2,
                            y: -proxy.size.height * 0.2
                        )
                        .blur(radius: 60)
                        .scaleEffect(animate ? 1.2 : 1.0)
                    
                    Circle()
                        .fill(ModernTheme.sageToLavender)
                        .frame(width: proxy.size.width * 0.7)
                        .offset(
                            x: proxy.size.width * 0.3,
                            y: proxy.size.height * 0.3
                        )
                        .blur(radius: 60)
                        .scaleEffect(animate ? 1.0 : 1.2)
                }
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(ModernTheme.sage)
                .symbolEffect(.bounce, value: true)
            
            Text("fortune_types".localized)
                .font(ModernTheme.Typography.largeTitle)
                .foregroundColor(ModernTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("discover_your_future".localized)
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 20)
    }
}

struct CategoryCard: View {
    let category: FortuneCategory
    let isSelected: Bool
    
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: category.gradientColors.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(category.gradientColors[0])
                    .symbolEffect(.bounce, value: bounceScale)
            }
            .scaleEffect(bounceScale)
            
            // Text Container
            VStack(spacing: 8) {
                Text(category.title)
                    .font(ModernTheme.Typography.headline)
                    .foregroundColor(ModernTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(category.description)
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(ModernTheme.surface)
                .shadow(
                    color: isSelected ? category.gradientColors[0].opacity(0.3) : Color.black.opacity(0.05),
                    radius: isSelected ? 20 : 10,
                    x: 0,
                    y: isSelected ? 8 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isSelected ? category.gradientColors[0].opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .opacity(category.isAvailable ? 1.0 : 0.6)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onAppear {
            if category.isAvailable {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    bounceScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
    }
}

struct LanguageSelectorButton: View {
    @Binding var showLanguageSelection: Bool
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: { showLanguageSelection.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                Text(getCurrentLanguageText())
                    .font(ModernTheme.Typography.caption)
            }
            .foregroundColor(ModernTheme.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(ModernTheme.surface)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
        }
    }
    
    private func getCurrentLanguageText() -> String {
        return localizationManager.currentLanguage == "en" ?
            "language_english".localized :
            "language_turkish".localized
    }
}

struct CategorySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectionView()
    }
}
