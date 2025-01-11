import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(ModernTheme.sage)
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("loading".localized)
                    .font(ModernTheme.Typography.headline)
                    .foregroundColor(ModernTheme.surface)
            }
        }
    }
}

#Preview {
    SplashScreen()
}
