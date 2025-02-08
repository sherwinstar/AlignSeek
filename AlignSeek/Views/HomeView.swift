import SwiftUI
import Photos
import AVFoundation

struct HomeView: View {
    @State private var showingSidebar = false
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage = ""
    @FocusState private var isFocused: Bool
    @State private var textViewHeight: CGFloat = 44
    @State private var isSearchSelected = false
    @State private var isReasoningSelected = false
    @State private var showingPlusMenu = false
    @State private var plusButtonFrame: CGRect = .zero // 存储加号按钮的位置
    @State private var isRecording = false
    @State private var isShowingRecordingPage = false
    
    var body: some View {
        NavigationView {
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
                            Text("Test ✨")
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
                        // 输入框和录音界面
                        if isRecording {
                            RecordingView(isRecording: $isRecording)
                                .transition(.opacity)
                        } else {
                            // 输入框
                            ZStack(alignment: .leading) {
                                AdaptiveTextView(text: $inputMessage, height: $textViewHeight, placeholder: "消息")
                                    .frame(height: textViewHeight)
                                
                                if inputMessage.isEmpty {
                                    Text("消息")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.white)
                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 0)
                            )
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 20,
                                    bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20
                                )
                            )
                            .overlay(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 20,
                                    bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20
                                )
                                .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
                            )
                            .focused($isFocused)
                            .transition(.opacity)
                        }
                        
                        // 底部工具栏
                        HStack {
                            // 左侧按钮组
                            HStack(spacing: 16) {
                                Button(action: { 
                                    showingPlusMenu.toggle()
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(isSearchSelected || isReasoningSelected ? .gray : .black)
                                        .frame(width: 36, height: 36)
                                        .background(Color(UIColor.systemGray6))
                                        .clipShape(Circle())
                                }
                                .disabled(isSearchSelected || isReasoningSelected)
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear.onAppear {
                                            plusButtonFrame = geometry.frame(in: .global)
                                        }
                                    }
                                )
                                
                                Button(action: { isSearchSelected.toggle() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 24))
                                            .foregroundColor(isSearchSelected ? .blue : .black)
                                        Text("搜索")
                                            .font(.system(size: 17))
                                            .foregroundColor(isSearchSelected ? .blue : .black)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSearchSelected ? Color.blue.opacity(0.1) : .clear)
                                    .clipShape(Capsule())
                                }
                                
                                Button(action: { isReasoningSelected.toggle() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lightbulb")
                                            .font(.system(size: 24))
                                            .foregroundColor(isReasoningSelected ? .blue : .black)
                                        Text("推理")
                                            .font(.system(size: 17))
                                            .foregroundColor(isReasoningSelected ? .blue : .black)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isReasoningSelected ? Color.blue.opacity(0.1) : .clear)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            // 右侧按钮组
                            HStack(spacing: 16) {
                                Button(action: {
                                    isRecording = true
                                }) {
                                    Image(systemName: "mic")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                }
                                
                                Button(action: {
                                    if !inputMessage.isEmpty {
                                        sendMessage()
                                    } else {
                                        isShowingRecordingPage = true
                                    }
                                }) {
                                    Image(systemName: inputMessage.isEmpty ? "waveform" : "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.vertical, 8)
                        .background(.white)
                    }
                    .background(.white)
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
                
                // 弹出菜单
                if showingPlusMenu {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingPlusMenu = false
                        }
                    
                    VStack {
                        Spacer()
                        HStack {
                            PlusMenuView(isPresented: $showingPlusMenu)
                                .padding(.horizontal)
                                .padding(.bottom, 60)
                                .scaleEffect(showingPlusMenu ? 1 : 0.1)
                                .offset(x: showingPlusMenu ? 0 : (plusButtonFrame.minX - UIScreen.main.bounds.width * 0.2),
                                       y: showingPlusMenu ? 0 : (plusButtonFrame.minY - UIScreen.main.bounds.height + 60))
                            Spacer()
                        }
                    }
                }
                
                // 录音页面导航链接
                NavigationLink(isActive: $isShowingRecordingPage) {
                    RecordingPageView()
                } label: {
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingPlusMenu)
            .navigationBarHidden(true)
        }
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
