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
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.managedObjectContext) private var viewContext
    
    // 添加当前会话状态
    @State private var currentSession: ChatSession?
    
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
                        
                        Button(action: {
                            createNewChat()
                        }) {
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
                                GeometryReader { geometry in
                                    AdaptiveTextView(text: $inputMessage, height: $textViewHeight, placeholder: "消息")
                                        .frame(width: geometry.size.width)  // 减去左右padding
                                        .frame(height: textViewHeight)
                                }
                                .frame(height: textViewHeight)
                                
                                if inputMessage.isEmpty {
                                    Text("消息")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 0)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            }
                            .padding(.horizontal, 12)  // 添加水平padding
//                            .background(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .fill(.white)
//                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 0)
//                            )
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 20,
                                    bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20
                                )
                            )
                            .overlay(
                                GeometryReader { geometry in
                                    Path { path in
                                        let w = geometry.size.width
                                        let radius: CGFloat = 20
                                        
                                        // 只绘制上半部分
                                        path.move(to: CGPoint(x: 0, y: radius))  // 从左边开始
                                        path.addArc(center: CGPoint(x: radius, y: radius),
                                                   radius: radius,
                                                   startAngle: .degrees(180),
                                                   endAngle: .degrees(270),
                                                   clockwise: false)  // 左上角圆弧
                                        path.addLine(to: CGPoint(x: w - radius, y: 0))  // 上边线
                                        path.addArc(center: CGPoint(x: w - radius, y: radius),
                                                   radius: radius,
                                                   startAngle: .degrees(270),
                                                   endAngle: .degrees(0),
                                                   clockwise: false)  // 右上角圆弧
                                    }
                                    .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
                                }
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
            .onAppear {
                loadLatestSession()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // 如果没有当前会话，创建一个新会话
        if currentSession == nil {
            currentSession = CoreDataManager.shared.createChatSession(
                id: UUID().uuidString,  // 使用UUID作为会话ID
                email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
                title: "New Chat"
            )
        }
        
        guard let session = currentSession else { return }
        
        // 创建用户消息
        let userMessage = CoreDataManager.shared.createChatMessage(
            content: trimmedMessage,
            isUser: true,
            session: session
        )
        messages.append(userMessage)
        inputMessage = ""
        isFocused = false
        
        // 调用 API 获取 AI 响应
        APIService.shared.sendMessage(trimmedMessage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let aiMessage = CoreDataManager.shared.createChatMessage(
                        content: response,
                        isUser: false,
                        session: session
                    )
                    messages.append(aiMessage)
                    
                case .failure(let error):
                    print("API Error: \(error.localizedDescription)")
                    // TODO: 显示错误提示
                }
            }
        }
    }
    
    // 添加创建新会话的方法
    private func createNewChat() {
        // 清空当前会话和消息
        currentSession = nil
        messages.removeAll()
        
        // 创建新会话
        currentSession = CoreDataManager.shared.createChatSession(
            id: UUID().uuidString,
            email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
            title: "New Chat"
        )
    }
    
    private func logout() {
        isLoggedIn = false  // 这会清除登录状态
        // 可以在这里清除其他需要的数据
    }
    
    private func loadLatestSession() {
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let sessions = CoreDataManager.shared.fetchChatSessions(for: email)
        if let latestSession = sessions.first {
            currentSession = latestSession
            messages = CoreDataManager.shared.fetchChatMessages(for: latestSession.id!)
        }
    }
} 
