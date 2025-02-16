import SwiftUI

struct FortuneTextDisplay: View {
    let text: String
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    
    @State private var previousSentenceIndex: Int = 0
    @State private var sentences: [String] = []
    @State private var sentenceStartTimes: [TimeInterval] = []
    
    /// Figures out which sentence should be highlighted based on audio progress
    private var currentSentenceIndex: Int {
        // Find the first sentence start time that's *greater* than currentTime
        if let index = sentenceStartTimes.firstIndex(where: { $0 > currentTime }) {
            // Highlight the sentence *just before* that time
            return max(0, index - 1)
        } else {
            // If no start time is greater, we’re at the last sentence
            return max(0, sentences.count - 1)
        }
    }
    
    private func prepareTextData() {
        // 1. Split full text into individual sentences
        var tempSentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                tempSentences.append(s)
            }
        }
        sentences = tempSentences
        
        // 2. Calculate how many total characters in all sentences
        let characterCounts = sentences.map { $0.count }
        let totalCharacters = characterCounts.reduce(0, +)
        
        // 3. Derive time offsets per sentence
        //    using raw duration / totalCharacters
        //    (no minimum duration enforced)
        let timePerChar: TimeInterval = totalCharacters == 0
            ? 0
            : (duration / TimeInterval(totalCharacters))
        
        var times: [TimeInterval] = []
        var cumulativeTime: TimeInterval = 0
        
        for count in characterCounts {
            // Record the time we start the next sentence
            times.append(cumulativeTime)
            // Advance cumulativeTime by (# of chars * timePerChar)
            cumulativeTime += Double(count) * timePerChar
        }
        
        sentenceStartTimes = times
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Extra space at the top so first highlighted sentence can scroll into view
                    Color.clear.frame(height: 60)
                    
                    // Render each sentence
                    ForEach(Array(sentences.enumerated()), id: \.offset) { (index, sentence) in
                        Text(sentence)
                            .font(.body)
                            .foregroundColor(
                                index == currentSentenceIndex
                                ? Color.black              // Highlight color
                                : Color.black.opacity(0.9) // Normal color
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(index == currentSentenceIndex
                                          ? Color.orange.opacity(0.15)
                                          : Color.clear)
                            )
                            .id(index)
                    }
                    
                    // Extra space at the bottom so last highlighted sentence can center
                    Color.clear.frame(height: 60)
                }
                .padding(.vertical, 20)
                .onAppear {
                    prepareTextData()
                }
                .onChange(of: currentTime) { _ in
                    let newIndex = currentSentenceIndex
                    if newIndex != previousSentenceIndex {
                        previousSentenceIndex = newIndex
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(
            color: Color.gray.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}
