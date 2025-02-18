//
//  ContentView.swift
//  ProjectKahve
//

import SwiftUI
import AVFoundation
import UIKit

extension UIApplication {
    func keepScreenOn(_ on: Bool) {
        UIApplication.shared.isIdleTimerDisabled = on
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var creditsManager: CreditsManager
    @StateObject private var audioManager = AudioPlayerManager()
    @GestureState private var dragOffset = CGSize.zero
    
    @State private var fortuneImages = FortuneImages()
    @State private var isShowingCupPicker = false
    @State private var isShowingPlatePicker = false
    @State private var isProcessing = false
    @State private var isLoading = false
    @State private var fadeInOpacity = 0.0
    @State private var showFullImage = false
    @State private var appearOpacity = 0.0
    @State private var showLanguageSelection = false
    @State private var showPurchaseView = false
    @State private var showCreditsDetail = false
    @State private var selectedImage: FortuneImageType?
    @State private var animateProcessing = false
    @State private var fortuneText: String = ""
    @State private var showFortuneText: Bool = false
    
    var body: some View {
        ZStack {
            BackgroundView(animate: true)
            
            ScrollView {
                VStack(spacing: 25) {
                    HeaderBar()
                    FortuneContentView()
                    ActionButtonsView()
                }
                .padding()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            LanguageSelectorButton(showLanguageSelection: $showLanguageSelection)
                .padding(.trailing, 24)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: $isShowingCupPicker) {
            ImagePicker(selectedImage: $fortuneImages.cupImage, imageType: .cup)
        }
        .sheet(isPresented: $isShowingPlatePicker) {
            ImagePicker(selectedImage: $fortuneImages.plateImage, imageType: .plate)
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
        .sheet(isPresented: $showCreditsDetail) {
            CreditsDetailView()
        }
        .opacity(appearOpacity)
        .onAppear {
            // Fade-in effect
            withAnimation(.easeIn(duration: 0.3)) {
                appearOpacity = 1.0
            }
            
            // If there's a previously saved fortune text, load it
            if let savedText = UserDefaults.standard.string(forKey: "lastCoffeeFortuneText"),
               !savedText.isEmpty {
                self.fortuneText = savedText
            }
            
            // If there's no cup image, hide any leftover fortune text
            // so user sees "Select Cup Photo" button right away
            if fortuneImages.cupImage == nil {
                self.showFortuneText = false
            }
        }
        .onChange(of: isProcessing) { newValue in
            UIApplication.shared.keepScreenOn(newValue)
        }
        .onChange(of: audioManager.isPlaying) { newValue in
            UIApplication.shared.keepScreenOn(newValue)
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    // Swipe right to dismiss
                    if value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    // MARK: - Helper Methods
    private func resetStates() {
        audioManager.stop()
        isProcessing = false
        showFullImage = false
        showFortuneText = false
    }
    
    // MARK: - Header Bar
    private func HeaderBar() -> some View {
        HStack {
            Button(action: {
                withAnimation(.easeIn(duration: 0.2)) {
                    dismiss()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("back".localized)
                }
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.sage)
            }
            
            Spacer()
            
            // Credits Button
            Button(action: {
                showCreditsDetail = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                    Text(String(format: "credits_remaining".localized, creditsManager.remainingCredits))
                        .font(ModernTheme.Typography.body)
                }
                .foregroundColor(ModernTheme.sage)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(ModernTheme.sage.opacity(0.1))
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Fortune Content View
    private func FortuneContentView() -> some View {
        VStack(spacing: 30) {
            // Title and Icon
            VStack(spacing: 16) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ModernTheme.sage)
                    .symbolEffect(.bounce, value: isProcessing)
                
                Text("coffee_fortune_reading".localized)
                    .font(ModernTheme.Typography.title)
                    .foregroundColor(ModernTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Image Display or Fortune Text Section
            ZStack {
                if isProcessing {
                    ProcessingView(fortuneImages: fortuneImages)
                        .transition(.opacity)
                } else if showFortuneText {
                    FortuneTextDisplay(
                        text: fortuneText,
                        currentTime: .init(
                            get: { audioManager.currentTime },
                            set: { _ in }
                        ),
                        duration: audioManager.duration
                    )
                    .frame(height: 300)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .opacity
                    ))
                } else if fortuneImages.cupImage != nil || fortuneImages.plateImage != nil {
                    ImagesDisplayView(
                        fortuneImages: fortuneImages,
                        showFullImage: $showFullImage
                    )
                } else {
                    UploadPromptView()
                }
            }
            .frame(height: 300)
            .padding(.top, 20) // <-- Added extra padding to avoid overlap
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessing)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFortuneText)
        }
    }
    
    // MARK: - Supporting Views
    private func ProcessingView(fortuneImages: FortuneImages) -> some View {
        VStack(spacing: 12) {
            // 1) Top text: "Processing your fortune..."
            Text("processing_fortune".localized)
                .font(ModernTheme.Typography.headline)
                .foregroundColor(ModernTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding()
                .opacity(fadeInOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                        fadeInOpacity = 1.0
                    }
                }
            
            // 2) Image (the green effect)
            if let cupImage = fortuneImages.cupImage {
                ImageProcessingView(image: cupImage)
                    .frame(width: 220, height: 220)
            }
            
            // 3) The “stay in the app” text
            Text("stay_in_app_while_processing".localized)
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
            
            // 4) Additional warning for irrelevant images
            Text("irrelevant_image_warning".localized)
                .font(ModernTheme.Typography.body)
                .foregroundColor(ModernTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func ImagesDisplayView(
        fortuneImages: FortuneImages,
        showFullImage: Binding<Bool>
    ) -> some View {
        HStack(spacing: 20) {
            if let cupImage = fortuneImages.cupImage {
                FortuneImageView(
                    image: cupImage,
                    title: "coffee_cup".localized,
                    showFullImage: showFullImage
                )
            }
            if let plateImage = fortuneImages.plateImage {
                FortuneImageView(
                    image: plateImage,
                    title: "coffee_plate".localized,
                    showFullImage: showFullImage
                )
            }
        }
    }
    
    private func FortuneImageView(
        image: UIImage,
        title: String,
        showFullImage: Binding<Bool>
    ) -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(ModernTheme.sage.opacity(0.1))
                    .frame(width: showFullImage.wrappedValue ? 300 : 180)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: showFullImage.wrappedValue ? 280 : 160,
                        height: showFullImage.wrappedValue ? 280 : 160
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(ModernTheme.sage, lineWidth: 3)
                    )
                    .shadow(color: ModernTheme.sage.opacity(0.2), radius: 10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showFullImage.wrappedValue.toggle()
                }
            }
            
            Text(title)
                .font(ModernTheme.Typography.caption)
                .foregroundColor(ModernTheme.textSecondary)
        }
    }
    
    private func UploadPromptView() -> some View {
        Button(action: {
            isShowingCupPicker = true
            resetStates()
        }) {
            VStack {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ModernTheme.sage.opacity(0.7))
                
                Text("select_cup_photo".localized)
                    .font(ModernTheme.Typography.body)
                    .foregroundColor(ModernTheme.textSecondary)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Action Button
    private func ActionButton(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        style: ButtonStyle = .primary
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(ModernTheme.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if style == .primary {
                        ModernTheme.primaryGradient
                    } else {
                        ModernTheme.surface
                    }
                }
            )
            .foregroundColor(style == .primary ? .white : ModernTheme.textPrimary)
            .cornerRadius(16)
            .shadow(
                color: style == .primary ?
                    ModernTheme.sage.opacity(0.3) : Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Action Buttons View
    private func ActionButtonsView() -> some View {
        VStack(spacing: 16) {
            // Hide cup/plate selection & optional text if reading is in progress OR reading is done
            if !isProcessing && !showFortuneText {
                if fortuneImages.cupImage == nil {
                    // No cup image yet
                    ActionButton(
                        title: "select_cup".localized,
                        icon: "cup.and.saucer.fill",
                        action: {
                            isShowingCupPicker = true
                            resetStates()
                        }
                    )
                } else {
                    // Cup photo exists
                    if fortuneImages.plateImage == nil {
                        // Plate photo is missing
                        VStack(spacing: 12) {
                            ActionButton(
                                title: "select_plate".localized,
                                icon: "circle.fill",
                                action: {
                                    isShowingPlatePicker = true
                                    resetStates()
                                }
                            )
                            
                            // Only show "Read Fortune" if no TTS is available yet
                            if audioManager.duration == 0 {
                                ActionButton(
                                    title: "read_fortune".localized,
                                    icon: "sparkles",
                                    action: {
                                        withAnimation {
                                            isProcessing = true
                                            showFullImage = false
                                        }
                                        sendImageToAPI()
                                    }
                                )
                            }
                            
                            // Plate photo is optional
                            Text("plate_photo_optional".localized)
                                .font(ModernTheme.Typography.caption)
                                .foregroundColor(ModernTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    } else {
                        // Both cup & plate images exist
                        // Only show "Read Fortune" if no TTS is available yet
                        if audioManager.duration == 0 {
                            ActionButton(
                                title: "read_fortune".localized,
                                icon: "sparkles",
                                action: {
                                    withAnimation {
                                        isProcessing = true
                                        showFullImage = false
                                    }
                                    sendImageToAPI()
                                }
                            )
                        }
                    }
                }
            }
            
            // Audio Player Section
            if audioManager.duration > 0 && !isProcessing {
                VStack(spacing: 12) {
                    CustomAudioProgress(audioManager: audioManager)
                        .frame(height: 40)
                    
                    ActionButton(
                        title: audioManager.isPlaying ? "stop".localized : "listen_fortune".localized,
                        icon: audioManager.isPlaying ? "stop.circle" : "play.circle",
                        action: toggleAudio,
                        style: .secondary
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - API and Audio Methods
    private func sendImageToAPI() {
        guard let cupImage = fortuneImages.cupImage else {
            isProcessing = false
            return
        }
        
        // If plateImage is nil, we pass nil to the API so it uses the "cup-only" prompt
        let plateImage = fortuneImages.plateImage
        
        guard creditsManager.useCredit() else {
            showPurchaseView = true
            isProcessing = false
            return
        }
        
        // Pass exactly the plateImage or nil
        APIService.sendImageToAPI(cupImage: cupImage, plateImage: plateImage) { content in
            DispatchQueue.main.async {
                if let content = content {
                    print("Generated Caption: \(content)")
                    self.fortuneText = content
                    
                    // Save to UserDefaults so it persists for next time
                    UserDefaults.standard.set(content, forKey: "lastCoffeeFortuneText")
                    
                    // Generate TTS only once per new reading
                    self.textToSpeech(caption: content)
                } else {
                    withAnimation {
                        self.isProcessing = false
                    }
                    print("Failed to generate caption.")
                }
            }
        }
    }
    
    private func textToSpeech(caption: String) {
        isProcessing = true
        
        APIService.textToSpeech(caption: caption) { fileUrl in
            DispatchQueue.main.async {
                self.isProcessing = false
                if let fileUrl = fileUrl {
                    self.loadAndPlayAudio(from: fileUrl)
                } else {
                    print("Failed to generate audio.")
                }
            }
        }
    }
    
    private func toggleAudio() {
        if audioManager.isPlaying {
            audioManager.pause()
        } else {
            audioManager.play()
            withAnimation {
                showFortuneText = true
            }
        }
    }
    
    private func loadAndPlayAudio(from url: URL) {
        DispatchQueue.main.async {
            // First, stop any existing audio
            audioManager.stop()
            
            // Load audio but don't autoplay
            audioManager.loadAudio(from: url, autoplay: false)
            
            // Reveal the text content immediately
            withAnimation(.easeInOut(duration: 0.3)) {
                isProcessing = false
                showFortuneText = true
            }
            // User can manually tap the button to start playback
        }
    }
}

// MARK: - Button Style Enum
extension ContentView {
    enum ButtonStyle {
        case primary
        case secondary
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(CreditsManager.shared)
}
