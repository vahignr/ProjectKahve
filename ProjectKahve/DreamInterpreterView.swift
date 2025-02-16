import SwiftUI
import AVFoundation

struct DreamInterpreterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var creditsManager: CreditsManager
    @StateObject private var audioManager = AudioPlayerManager()
    
    // Dream text user types
    @State private var dreamText: String = ""
    
    // Final interpreted text from API
    @State private var interpretationText: String = ""
    
    // Processing states
    @State private var isProcessing = false
    @State private var showInterpretation = false
    
    // Sheets
    @State private var showPurchaseView = false
    @State private var showLanguageSelection = false
    @State private var showCreditsDetail = false
    
    // Min/max length & alert
    private let minCharacters = 20
    private let maxCharacters = 5000
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Fade-in
    @State private var appearOpacity = 0.0
    
    var body: some View {
        ZStack {
            BackgroundView(animate: true)
            
            // Main content
            VStack(spacing: 25) {
                headerBar()
                
                if !showInterpretation {
                    dreamInputSection()
                    characterCountView() // Shows "13/5000"
                }
                
                if isProcessing {
                    processingView()
                } else if showInterpretation {
                    interpretationSection()
                    
                    // If we have audio, show progress & listen button
                    if audioManager.duration > 0 {
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
                        .padding(.horizontal)
                        
                        newDreamButton()
                            .padding(.top, 10)
                    }
                }
                
                // Interpret Dream button if not processing or showing result
                if !showInterpretation && !isProcessing {
                    interpretButton()
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
            // Dismiss keyboard even if tapping the text box
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            // Language button at bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LanguageSelectorButton(showLanguageSelection: $showLanguageSelection)
                        .padding(.trailing, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .alert("notice".localized, isPresented: $showAlert) {
            Button("ok".localized, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        // Additional sheets
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView().environmentObject(creditsManager)
        }
        .sheet(isPresented: $showCreditsDetail) {
            CreditsDetailView().environmentObject(creditsManager)
        }
        // Fade in
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                appearOpacity = 1.0
            }
        }
        // Keep screen on during processing or audio
        .onChange(of: isProcessing) { UIApplication.shared.keepScreenOn($0) }
        .onChange(of: audioManager.isPlaying) { UIApplication.shared.keepScreenOn($0) }
    }
}

// MARK: - Subviews
extension DreamInterpreterView {
    
    private func headerBar() -> some View {
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
    
    private func dreamInputSection() -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ModernTheme.sage)
                    .symbolEffect(.bounce, value: true)
                
                // Replaced "dream_interpretation" with "dream_interpreter"
                Text("dream_interpreter".localized)
                    .font(ModernTheme.Typography.title)
                    .foregroundColor(ModernTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $dreamText)
                        .font(ModernTheme.Typography.body)
                        .foregroundColor(ModernTheme.textPrimary)
                        .frame(height: 200)
                        .scrollContentBackground(.hidden)
                        .background(ModernTheme.surface)
                    
                    if dreamText.isEmpty {
                        Text("dream_placeholder".localized)
                            .font(ModernTheme.Typography.body)
                            .foregroundColor(ModernTheme.textSecondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ModernTheme.surface)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
            }
            .padding(.top, 20)
        }
    }
    
    // Character count / 5000
    private func characterCountView() -> some View {
        HStack {
            // Example: "13/5,000"
            // If it's outside range (under 20 or over 5000) => show red
            let count = dreamText.count
            Text("\(count)/\(maxCharacters)")
                .font(ModernTheme.Typography.caption)
                .foregroundColor(
                    (count < minCharacters || count > maxCharacters)
                    ? Color.red
                    : ModernTheme.textSecondary
                )
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func interpretButton() -> some View {
        ActionButton(
            title: "interpret_dream".localized,
            icon: "sparkles",
            action: interpretDream
        )
    }
    
    private func processingView() -> some View {
        VStack(spacing: 12) {
            Text("processing_dream".localized)
                .font(ModernTheme.Typography.headline)
                .foregroundColor(ModernTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding()
            
            ProgressView()
                .tint(ModernTheme.sage)
                .scaleEffect(1.5)
                .padding()
        }
    }
    
    // Final text with highlight
    private func interpretationSection() -> some View {
        VStack(spacing: 20) {
            FortuneTextDisplay(
                text: interpretationText,
                currentTime: .init(
                    get: { audioManager.currentTime },
                    set: { _ in }
                ),
                duration: audioManager.duration
            )
            .frame(height: 300)
            .background(ModernTheme.surface)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
    
    private func newDreamButton() -> some View {
        Button(action: {
            withAnimation {
                dreamText = ""
                interpretationText = ""
                showInterpretation = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                Text("new_dream_interpretation".localized)
                    .font(ModernTheme.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ModernTheme.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: ModernTheme.sage.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Dream Interpretation Logic
extension DreamInterpreterView {
    private func interpretDream() {
        let trimmed = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Enforce min/max length
        if trimmed.count < minCharacters {
            alertMessage = String(format: "dream_text_too_short".localized, minCharacters)
            showAlert = true
            return
        }
        if trimmed.count > maxCharacters {
            alertMessage = String(format: "dream_text_too_long".localized, maxCharacters)
            showAlert = true
            return
        }
        
        // Use credit
        guard creditsManager.useCredit() else {
            showPurchaseView = true
            return
        }
        
        isProcessing = true
        showInterpretation = false
        
        // 1) Call dream interpretation API
        APIService.sendDreamToAPI(dreamText: trimmed) { content in
            DispatchQueue.main.async {
                self.isProcessing = false
                if let content = content {
                    // Store final text, then do TTS
                    self.interpretationText = content
                    self.generateTTS(for: content)
                } else {
                    print("Dream interpretation request failed (nil).")
                }
            }
        }
    }
    
    // 2) Generate TTS
    private func generateTTS(for text: String) {
        isProcessing = true
        
        APIService.textToSpeech(caption: text) { fileUrl in
            DispatchQueue.main.async {
                self.isProcessing = false
                self.showInterpretation = true
                if let fileUrl = fileUrl {
                    self.loadAndPlayAudio(from: fileUrl)
                }
            }
        }
    }
    
    // 3) Load TTS but do not autoplay
    private func loadAndPlayAudio(from url: URL) {
        audioManager.stop()
        audioManager.loadAudio(from: url, autoplay: false)
    }
    
    private func toggleAudio() {
        if audioManager.isPlaying {
            audioManager.pause()
        } else {
            audioManager.play()
        }
    }
    
    // Hide keyboard even if user taps the text box
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// -------------------------------------------------------
// If you do NOT already have an ActionButton, keep this.
// Otherwise, remove it if your project has it elsewhere.
// -------------------------------------------------------
fileprivate struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ButtonStyleType = .primary
    
    enum ButtonStyleType {
        case primary
        case secondary
    }
    
    var body: some View {
        switch style {
        case .primary:
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                    Text(title)
                        .font(ModernTheme.Typography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ModernTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(
                    color: ModernTheme.sage.opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
        case .secondary:
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                    Text(title)
                        .font(ModernTheme.Typography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ModernTheme.surface)
                .foregroundColor(ModernTheme.textPrimary)
                .cornerRadius(16)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 10,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}
