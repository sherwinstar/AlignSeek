import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isUser { Spacer() }
        }
    }
} 