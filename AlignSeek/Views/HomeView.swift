import SwiftUI

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(width: 280)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

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

struct HomeView: View {
    @State private var showingSidebar = false
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部按钮
                HStack {
                    Button(action: { showingSidebar.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("AlignSeek ✨")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                
                // 聊天区域
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // 底部区域
                VStack(spacing: 0) {
                    // 输入框
                    TextField("消息", text: $inputMessage)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // 底部工具栏
                    HStack(spacing: 0) {
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("新建")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "globe")
                                Text("搜索")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "lightbulb")
                                Text("推理")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "mic")
                                Text("语音")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // 动态切换发送/声音按钮
                        Button(action: {
                            if !inputMessage.isEmpty {
                                sendMessage()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: inputMessage.isEmpty ? "waveform" : "arrow.up.circle.fill")
                                    .foregroundColor(inputMessage.isEmpty ? .gray : .blue)
                                    .font(.system(size: inputMessage.isEmpty ? 20 : 24))
                                Text(inputMessage.isEmpty ? "声音" : "发送")
                                    .font(.caption)
                                    .foregroundColor(inputMessage.isEmpty ? .gray : .blue)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                }
                .background(Color(UIColor.systemBackground))
            }
            
            // 侧边栏和遮罩
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingSidebar = false
                    }
                
                HStack {
                    SidebarView(isPresented: $showingSidebar)
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showingSidebar)
    }
    
    private func sendMessage() {
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(content: trimmedMessage, isUser: true, timestamp: Date())
        messages.append(userMessage)
        inputMessage = ""
        
        // 发送消息后取消键盘焦点
        isFocused = false
        
        // 模拟AI响应
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiMessage = ChatMessage(content: "这是一个模拟的回复。", isUser: false, timestamp: Date())
            messages.append(aiMessage)
        }
    }
} 