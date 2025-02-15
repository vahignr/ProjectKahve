import SwiftUI

struct FortuneTextDisplay: View {
    let text: String
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval

    @State private var previousSentenceIndex: Int = 0
    @State private var sentences: [String] = []
    @State private var sentenceStartTimes: [TimeInterval] = []
    
    private var currentSentenceIndex: Int {
        if let index = sentenceStartTimes.firstIndex(where: { $0 > currentTime }) {
            return max(0, index - 1)
        } else {
            return max(0, sentences.count - 1)
        }
    }

    private func prepareTextData() {
        var tempSentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { (substring, _, _, _) in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                tempSentences.append(sentence)
            }
        }
        sentences = tempSentences

        let characterCounts = sentences.map { $0.count }
        let totalCharacters = characterCounts.reduce(0, +)
        let timePerChar = duration / TimeInterval(totalCharacters)
        
        var times: [TimeInterval] = []
        var cumulativeTime: TimeInterval = 0
        for count in characterCounts {
            times.append(cumulativeTime)
            cumulativeTime += TimeInterval(count) * timePerChar
        }
        sentenceStartTimes = times
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                        Text(sentence)
                            .font(.body)
                            .foregroundColor(index == currentSentenceIndex ?
                                Color.black :
                                Color.black.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(index == currentSentenceIndex ?
                                        Color.orange.opacity(0.15) :
                                        Color.clear
                                    )
                            )
                            .id(index)
                    }
                }
                .padding(.vertical, 20)
                .onAppear {
                    prepareTextData()
                    proxy.scrollTo(0, anchor: .top)
                }
                .onChange(of: currentTime) { _ in
                    let newIndex = currentSentenceIndex
                    if newIndex != previousSentenceIndex {
                        previousSentenceIndex = newIndex
                        withAnimation(.easeInOut(duration: 0.3)) {
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
