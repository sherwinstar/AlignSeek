import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // 显示所有附件
                if let mediaUrls = message.medias as? [String] {
                    ForEach(mediaUrls, id: \.self) { path in
                        let fullPath = getDocumentsDirectory().appendingPathComponent(path).path
                        if let image = UIImage(contentsOfFile: fullPath) {
                            // 显示图片
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            // 显示文件
                            HStack {
                                Image(systemName: "doc")
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .lineLimit(1)
                            }
                            .padding(12)
                            .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // 显示文本消息
                if !message.content!.isEmpty {
                    Text(message.content!)
                        .padding(12)
                        .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
} 
