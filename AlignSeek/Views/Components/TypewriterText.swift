import SwiftUI

struct TypewriterText: View {
    let text: String
    let isNewMessage: Bool
    let onTypingComplete: () -> Void
    @State private var displayedText: String = ""
    private let typingInterval: TimeInterval = 0.05
    
    var body: some View {
        Text(isNewMessage ? displayedText : text)
            .multilineTextAlignment(TextAlignment.leading)
            .onAppear {
                if isNewMessage {
                    startTyping()
                } else {
                    displayedText = text
                }
            }
    }
    
    private func startTyping() {
        displayedText = ""
        var currentIndex = 0
        let characters = Array(text)
        
        DispatchQueue.main.async {
            func typeNextCharacter() {
                if currentIndex < characters.count {
                    displayedText += String(characters[currentIndex])
                    currentIndex += 1
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + typingInterval) {
                        typeNextCharacter()
                    }
                } else {
                    onTypingComplete()
                }
            }
            
            typeNextCharacter()
        }
    }
} 
