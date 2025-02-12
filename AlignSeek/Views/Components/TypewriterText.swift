import SwiftUI

struct TypewriterText: View {
    let text: String
    let isNewMessage: Bool
    let onTypingComplete: () -> Void
    @State private var displayedText: AttributedString = AttributedString("")
    @State private var fullAttributedText: AttributedString = AttributedString("")
    private let typingInterval: TimeInterval = 0.05
    
    var body: some View {
        Text(isNewMessage ? displayedText : fullAttributedText)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)  // 允许文本选择
            .onAppear {
                let options = AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
                
                if let attributedText = try? AttributedString(markdown: text, options: options) {
                    fullAttributedText = attributedText
                    if isNewMessage {
                        startTyping()
                    } else {
                        displayedText = attributedText
                    }
                }
            }
    }
    
    private func startTyping() {
        displayedText = AttributedString("")
        var currentIndex = 0
        let characters = Array(text)
        
        DispatchQueue.main.async {
            func typeNextCharacter() {
                if currentIndex < characters.count {
                    let currentText = String(characters[..<(currentIndex + 1)])
                    let options = AttributedString.MarkdownParsingOptions(
                        interpretedSyntax: .inlineOnlyPreservingWhitespace
                    )
                    
                    // 尝试解析当前文本为 Markdown
                    if let partialText = try? AttributedString(markdown: currentText, options: options) {
                        displayedText = partialText
                    } else {
                        // 如果 Markdown 解析失败，使用普通文本
                        displayedText = AttributedString(currentText)
                    }
                    
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
