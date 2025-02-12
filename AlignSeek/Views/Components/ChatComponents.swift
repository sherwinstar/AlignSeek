import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let isNewMessage: Bool
    let onTypingComplete: () -> Void  // 添加回调
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var body: some View {
        HStack {
            if !message.isUser {
                // 整体内容
                VStack(alignment: .leading, spacing: 6) {  // 左对齐，垂直间距6dp
                    // AI 头像
                    Image("icon_ai")
                        .resizable()
                        .frame(width: 30, height: 30)
                    
                    // 消息内容
                    VStack(alignment: .leading, spacing: 8) {
                        // 显示文本消息
                        if !message.content!.isEmpty {
                            TypewriterText(
                                text: message.content!, 
                                isNewMessage: isNewMessage,
                                onTypingComplete: onTypingComplete  // 传递回调
                            )
                            .padding(12)
                            .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
                            .background(Color.white)
                            .foregroundColor(Color(hex: 0x1D2129))
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 8,
                                    bottomLeadingRadius: 8,
                                    bottomTrailingRadius: 8,
                                    topTrailingRadius: 8
                                )
                            )
                        }
                    }
                }
                  // 整体内容统一左边距16dp
                
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
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
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    // 显示文本消息
                    if !message.content!.isEmpty {
                        Text(message.content!)
                            .padding(12)
                            .background(message.isUser ? Color(hex: "1B2559") : Color(UIColor.systemGray5))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: message.isUser ? 16 : 8,
                                    bottomLeadingRadius: message.isUser ? 16 : 8,
                                    bottomTrailingRadius: message.isUser ? 0 : 8,
                                    topTrailingRadius: message.isUser ? 16 : 8
                                )
                            )
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .trailing)
            }
        }
    }
} 
