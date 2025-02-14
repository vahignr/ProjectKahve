import SwiftUI
import AVFoundation

// MARK: - Constants
private let lastDreamTextKey = "lastDreamText"
private let lastDreamInterpretationKey = "lastDreamInterpretation"
private let minCharacters = 20
private let maxCharacters = 5000

struct DreamInterpreterView: View {
   @Environment(\.dismiss) private var dismiss
   @StateObject private var localizationManager = LocalizationManager.shared
   @EnvironmentObject var creditsManager: CreditsManager
   @StateObject private var audioManager = AudioPlayerManager()
   @GestureState private var dragOffset = CGSize.zero
   @FocusState private var isTextFieldFocused: Bool
   
   @State private var dreamText: String = ""
   @State private var isProcessing = false
   @State private var showLanguageSelection = false
   @State private var showPurchaseView = false
   @State private var showCreditsDetail = false
   @State private var appearOpacity = 0.0
   @State private var interpretationText: String = ""
   @State private var showInterpretation: Bool = false
   @State private var showAlert = false
   @State private var alertMessage = ""
   @State private var showInputForm = false
   
   // Character count computed property
   private var characterCount: Int {
       dreamText.count
   }
   
   private var isValidDreamLength: Bool {
       characterCount >= minCharacters && characterCount <= maxCharacters
   }
   
   private var remainingCharacters: Int {
       maxCharacters - characterCount
   }
   
   var body: some View {
       ZStack {
           BackgroundView(animate: true)
           
           VStack(spacing: 25) {
               HeaderBar()
               if !showInterpretation {
                   DreamInputSection()
                   CharacterCountView()
               }
               
               if isProcessing {
                   ProcessingView()
               }
               
               if showInterpretation {
                   InterpretationSection()
               }
               
               ActionButtonsView()
               
               if showInterpretation && !isProcessing {
                   NewDreamButton()
               }
               
               Spacer()
           }
           .padding()
           .simultaneousGesture(
               TapGesture()
                   .onEnded { _ in
                       isTextFieldFocused = false
                   }
           )
           
           // Language selector positioned absolutely at the bottom
           VStack {
               Spacer()
               HStack {
                   Spacer()
                   LanguageSelectorButton(showLanguageSelection: $showLanguageSelection)
                       .padding(.trailing, 24)
                       .padding(.bottom, 16)
               }
           }
           .ignoresSafeArea(.keyboard)
       }
       .alert("notice".localized, isPresented: $showAlert) {
           Button("ok".localized, role: .cancel) { }
       } message: {
           Text(alertMessage)
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
           withAnimation(.easeIn(duration: 0.3)) {
               appearOpacity = 1.0
           }
           loadLastInterpretation()
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
                   if value.translation.width > 100 {
                       dismiss()
                   }
               }
       )
   }
   
   // MARK: - Character Count View
   private func CharacterCountView() -> some View {
       HStack {
           Text("\(characterCount)/\(maxCharacters)")
               .font(ModernTheme.Typography.caption)
               .foregroundColor(isValidDreamLength ? ModernTheme.textSecondary : .red)
           Spacer()
       }
       .padding(.horizontal, 20)
   }
   
   // MARK: - Load Last Interpretation
   private func loadLastInterpretation() {
       if let savedInterpretation = UserDefaults.standard.string(forKey: lastDreamInterpretationKey),
          let savedDream = UserDefaults.standard.string(forKey: lastDreamTextKey) {
           interpretationText = savedInterpretation
           dreamText = savedDream
           showInterpretation = true
           showInputForm = false
       } else {
           showInputForm = true
       }
   }
   
   // MARK: - New Dream Button
   private func NewDreamButton() -> some View {
       Button(action: {
           withAnimation {
               dreamText = ""
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
   
   // MARK: - Dream Input Section
   private func DreamInputSection() -> some View {
       VStack(spacing: 16) {
           VStack(spacing: 16) {
               Image(systemName: "moon.stars.fill")
                   .font(.system(size: 44))
                   .foregroundColor(ModernTheme.sage)
                   .symbolEffect(.bounce, value: true)
               
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
                       .focused($isTextFieldFocused)
                       .onChange(of: dreamText) { newValue in
                           if newValue.count > maxCharacters {
                               dreamText = String(newValue.prefix(maxCharacters))
                           }
                       }
                   
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
                       .shadow(color: Color.black.opacity(0.05), radius: 10)
               )
           }
           .padding(.top, 20)
       }
   }
   
   // MARK: - Interpretation Section
   private func InterpretationSection() -> some View {
       FortuneTextDisplay(
           text: interpretationText,
           currentTime: .init(
               get: { audioManager.currentTime },
               set: { _ in }
           ),
           duration: audioManager.duration
       )
       .frame(height: 300)
   }
   
   // MARK: - Processing View
   private func ProcessingView() -> some View {
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
           
           Text("stay_in_app_while_processing".localized)
               .font(ModernTheme.Typography.body)
               .foregroundColor(ModernTheme.textSecondary)
               .multilineTextAlignment(.center)
               .padding(.horizontal, 20)
               .fixedSize(horizontal: false, vertical: true)
       }
   }
   
   // MARK: - Action Buttons
   private func ActionButtonsView() -> some View {
       VStack(spacing: 16) {
           if !isProcessing {
               if !showInterpretation {
                   ActionButton(
                       title: "interpret_dream".localized,
                       icon: "sparkles",
                       action: interpretDream
                   )
               }
               
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
               }
           }
       }
       .padding(.horizontal, 20)
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
   
   // MARK: - Helper Methods
   private func interpretDream() {
       if !isValidDreamLength {
           if characterCount < minCharacters {
               alertMessage = String(format: "dream_text_too_short".localized, minCharacters)
           } else {
               alertMessage = String(format: "dream_text_too_long".localized, maxCharacters)
           }
           showAlert = true
           return
       }
       
       guard creditsManager.useCredit() else {
           showPurchaseView = true
           return
       }
       
       isTextFieldFocused = false
       
       withAnimation {
           isProcessing = true
           showInterpretation = false
       }
       
       APIService.sendDreamToAPI(dreamText: dreamText) { content in
           DispatchQueue.main.async {
               if let content = content {
                   self.interpretationText = content
                   
                   // Save the dream and interpretation
                   UserDefaults.standard.set(self.dreamText, forKey: lastDreamTextKey)
                   UserDefaults.standard.set(content, forKey: lastDreamInterpretationKey)
                   
                   // Generate TTS for the interpretation
                   APIService.textToSpeech(caption: content) { fileUrl in
                       DispatchQueue.main.async {
                           self.isProcessing = false
                           self.showInterpretation = true
                           if let fileUrl = fileUrl {
                               self.loadAndPlayAudio(from: fileUrl)
                           }
                       }
                   }
               } else {
                   withAnimation {
                       self.isProcessing = false
                   }
                   alertMessage = "dream_api_error".localized
                   showAlert = true
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
               showInterpretation = true
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
               showInterpretation = true
           }
       }
   }
}

// MARK: - Button Style Enum
extension DreamInterpreterView {
   enum ButtonStyle {
       case primary
       case secondary
   }
}

struct DreamInterpreterView_Previews: PreviewProvider {
   static var previews: some View {
       DreamInterpreterView()
           .environmentObject(CreditsManager.shared)
   }
}
