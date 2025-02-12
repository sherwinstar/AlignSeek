import SwiftUI
import Photos
import AVFoundation

struct HomeView: View {
    @State private var showingSidebar = false
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage = ""
    @FocusState private var isFocused: Bool
    @State private var textViewHeight: CGFloat = 52
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
    
    @State private var selectedAttachments: [AttachmentItem] = []  // 存储选中的附件
    
    // 添加一个属性来跟踪新消息的 ID
    @State private var newMessageId: Int64?
    
    // 定义附件类型
    enum AttachmentType {
        case image(UIImage)
        case file(URL)
    }
    
    // 附件项结构
    struct AttachmentItem: Identifiable {
        let id = UUID()
        let type: AttachmentType
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(hex: 0xE5E6EB)  // 修改背景色为 #E5E6EB
                        .ignoresSafeArea()
                    
                    // 主内容
                    VStack(spacing: 0) {
                        // 顶部按钮
                        HStack {
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                    showingSidebar.toggle()
                                }
                                // 隐藏键盘
                                isFocused = false
                            }) {
                                Image("icon_menu")
                                    .frame(width: 29, height: 29)
                            }
                            
                            Spacer()
                            
                            Text("New Chat")
                                .font(.system(size: 16))
                                .fontWeight(Font.Weight.bold)
                                .foregroundColor(Color(hex: 0x222222, alpha: 1))
                            
                            
                            Spacer()
                            
                            Button(action: {
                                createNewChat()
                                // 隐藏键盘
                                isFocused = false
                            }) {
                                Image("icon_plus_circle")
                                    .frame(width: 29, height: 29)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 聊天区域
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isNewMessage: message.id == newMessageId,
                                        onTypingComplete: {
                                            // 打字效果完成后，清除 newMessageId
                                            if message.id == newMessageId {
                                                newMessageId = nil
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .simultaneousGesture(
                            DragGesture().onChanged { _ in
                                // 滚动时隐藏键盘
                                isFocused = false
                            }
                        )
                        .onTapGesture {
                            // 点击时隐藏键盘
                            isFocused = false
                        }
                        
                        // 底部区域
                        VStack(spacing: 0) {
                            if isRecording {
                                RecordingView(isRecording: $isRecording) { transcription in
                                    // 将转写的文字添加到输入框
                                    inputMessage = transcription
                                    print("222:" + transcription)
                                }
                                .transition(.opacity)
                            } else {
                                // 输入框区域
                                VStack(spacing: 0) {
                                    VStack(spacing: 4) {
                                        if !selectedAttachments.isEmpty {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(selectedAttachments) { attachment in
                                                        AttachmentPreviewView(item: attachment) {
                                                            if let index = selectedAttachments.firstIndex(where: { $0.id == attachment.id }) {
                                                                selectedAttachments.remove(at: index)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.trailing, 12)
                                            }
                                            .frame(height: 70)
                                        }
                                        
                                        HStack(spacing: 6) {  // 添加水平布局，spacing为12dp
                                            AdaptiveTextViewWithPlaceholder(
                                                text: $inputMessage,
                                                height: $textViewHeight,
                                                placeholder: "To send a message to HKChat"
                                            )
                                            .frame(height: textViewHeight)
                                            
                                            // 发送按钮
                                            Button(action: {
                                                if !inputMessage.isEmpty {
                                                    sendMessage()
                                                }
                                            }) {
                                                Image(inputMessage.isEmpty ? "icon_send": "icon_send_enable")
                                                    .frame(width: 24, height: 24)
                                                
//                                                Image("icon_send")
//                                                    .renderingMode(.template)
//                                                    .frame(width: 24, height: 24)
//                                                    .foregroundColor(inputMessage.isEmpty ? 
//                                                        Color(hex: 0x1B2559).opacity(0.2) :  // 空时是 #1B2559 20%透明度
//                                                        Color(hex: 0x1D2129)                 // 非空时是 #191D28 不透明
//                                                    )
                                            }
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 12)  // 右边距12dp
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            isFocused = true
                                        }
                                    }
                                    
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "E5E6EB"), lineWidth: 1)
                                )
                                .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                .focused($isFocused)
                                .padding(.horizontal, 16)
                            }
                            
                            // 底部工具栏
                            HStack {
                                // 左侧按钮组
                                HStack(spacing: 4) {
                                    Button(action: { 
                                        showingPlusMenu.toggle()
                                    }) {
                                        Image("icon_add_file")
                                            .frame(width: 29, height: 29)
                                            .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                    }
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear.onAppear {
                                                plusButtonFrame = geometry.frame(in: .global)
                                            }
                                        }
                                    )
                                    
                                    Button(action: { isReasoningSelected.toggle() }) {
                                        HStack(spacing: 4) {
                                            Image("icon_lamp")
                                                .renderingMode(.template)
                                                .frame(width: 18, height: 18)
                                                .padding(.vertical, 5.5)
                                                .foregroundColor(isReasoningSelected ? Color(hex: 0x206EFF, alpha: 1) : Color(hex: 0x828282, alpha: 1))
                                            Text("Deepthink")
                                                .font(.system(size: 15))
                                                .fontWeight(Font.Weight.medium)
                                                .foregroundColor(isReasoningSelected ? Color(hex: 0x206EFF, alpha: 1) : Color(hex: 0x828282, alpha: 1))
                                        }
                                        .padding(.horizontal, 6)
                                        .background(isReasoningSelected ? Color(hex: "EBF2FF") : .white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isReasoningSelected ? Color(hex: "C0D6FF") : Color(hex: "E5E6EB"), lineWidth: 1)
                                        )
                                        .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                    }
                                    
                                    Button(action: { isSearchSelected.toggle() }) {
                                        HStack(spacing: 4) {
                                            Image("icon_globe")
                                                .renderingMode(.template)
                                                .frame(width: 18, height: 18)
                                                .padding(.vertical, 5.5)
                                                .foregroundColor(isSearchSelected ? Color(hex: 0x206EFF, alpha: 1) : Color(hex: 0x828282, alpha: 1))
                                            Text("Search")
                                                .font(.system(size: 15))
                                                .fontWeight(Font.Weight.medium)
                                                .foregroundColor(isSearchSelected ? Color(hex: 0x206EFF, alpha: 1) : Color(hex: 0x828282, alpha: 1))
                                        }
                                        .padding(.horizontal, 6)
                                        .background(isSearchSelected ? Color(hex: "EBF2FF") : .white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isSearchSelected ? Color(hex: "C0D6FF") : Color(hex: "E5E6EB"), lineWidth: 1)
                                        )
                                        .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                    }
                                    
                                    
                                }
                                .padding(.leading)
                                
                                Spacer()
                                
                                // 右侧按钮组
                                HStack(spacing: 4) {
                                    Button(action: {
                                        isRecording = true
                                    }) {
                                        Image("icon_audio")
                                            .frame(width: 29, height: 29)
                                            .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                    }
                                    
                                    Button(action: {
                                        isShowingRecordingPage = true
                                    }) {
                                        Image("icon_wave")
                                            .frame(width: 29, height: 29)
                                            .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
                                    }
                                }
                                .padding(.trailing)
                            }
                            .padding(.vertical, 8)
                            .background(.white)
                        }
                        .background(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 遮罩和侧边栏
                    if showingSidebar {
                        ZStack {
                            // 遮罩
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                        showingSidebar = false
                                    }
                                }
                                .transition(.opacity)
                            
                            // 侧边栏
                            HStack(spacing: 0) {
                                SidebarView(
                                    isPresented: $showingSidebar,
                                    currentSession: $currentSession,
                                    onSessionSelected: { session in
                                        currentSession = session
                                        messages = CoreDataManager.shared.fetchChatMessages(for: session.id!)
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                            showingSidebar = false
                                        }
                                    }
                                )
                                
                                Spacer()
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        .zIndex(1)  // 确保遮罩和侧边栏在最上层
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
                                PlusMenuView(isPresented: $showingPlusMenu,
                                            onImageSelected: { image in
                                    selectedAttachments.append(AttachmentItem(type: .image(image)))
                                }, onFileSelected: { url in
                                    selectedAttachments.append(AttachmentItem(type: .file(url)))
                                })
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
            }
            .navigationBarHidden(true)
            .onAppear {
                loadLatestSession()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果没有文本和附件，不发送
        guard !trimmedMessage.isEmpty || !selectedAttachments.isEmpty else { return }
        
        // 如果没有当前会话，创建一个新会话
        if currentSession == nil {
            currentSession = CoreDataManager.shared.createChatSession(
                id: UUID().uuidString,
                email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
                title: trimmedMessage
            )
        }
        
        guard let session = currentSession else { return }
        
        // 创建一条消息，包含文本和所有附件
        let message = CoreDataManager.shared.createChatMessage(
            content: trimmedMessage,
            isUser: true,
            session: session
        )
        
        // 存储所有附件并收集URL
        var mediaUrls: [String] = []
        
        for attachment in selectedAttachments {
            switch attachment.type {
            case .image(let image):
                if let imageURL = saveImageToDocuments(image) {
                    // 只存储文件名
                    mediaUrls.append(imageURL.lastPathComponent)
                }
            case .file(let url):
                if let savedURL = saveFileToDocuments(url) {
                    // 只存储文件名
                    mediaUrls.append(savedURL.lastPathComponent)
                }
            }
        }
        
        // 设置媒体数组
        message.medias = mediaUrls as NSObject
        try? CoreDataManager.shared.context.save()
        
        messages.append(message)
        
        // 清理状态
        inputMessage = ""
        selectedAttachments = []
        isFocused = false
        
        // 调用 API 获取 AI 响应
        if mediaUrls.isEmpty {
            APIService2.shared.sendMessage(trimmedMessage) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        let aiMessage = CoreDataManager.shared.createChatMessage(
                            content: response,
                            isUser: false,
                            session: session
                        )
                        messages.append(aiMessage)
                        newMessageId = aiMessage.id  // 标记新消息
                        
                    case .failure(let error):
                        print("API Error: \(error.localizedDescription)")
                        // TODO: 显示错误提示
                    }
                }
            }
        } else {
            APIService.shared.sendMessage(trimmedMessage, message: message) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        let aiMessage = CoreDataManager.shared.createChatMessage(
                            content: response,
                            isUser: false,
                            session: session
                        )
                        messages.append(aiMessage)
                        newMessageId = aiMessage.id  // 标记新消息
                        
                    case .failure(let error):
                        print("API Error: \(error.localizedDescription)")
                        // TODO: 显示错误提示
                    }
                }
            }
        }
    }
    
    // 保存图片到文档目录
    private func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // 保存文件到文档目录
    private func saveFileToDocuments(_ sourceURL: URL) -> URL? {
        let filename = UUID().uuidString + "_" + sourceURL.lastPathComponent
        let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }
    
    // 添加创建新会话的方法
    private func createNewChat() {
        // 清空当前会话和消息
        currentSession = nil
        messages.removeAll()
        // 清空输入框和预览区域
        inputMessage = ""
        selectedAttachments = []
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
    
    // 附件预览组件
    struct AttachmentPreviewView: View {
        let item: AttachmentItem
        let onDelete: () -> Void
        
        var body: some View {
            ZStack(alignment: .topTrailing) {
                switch item.type {
                case .image(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)  // 添加顶部内边距给删除按钮留空间
                        .padding(.trailing, 8)  // 添加右侧内边距给删除按钮留空间
                case .file(let url):
                    VStack(spacing: 2) {
                        Image(systemName: "doc")
                            .font(.system(size: 24))
                        Text(url.lastPathComponent)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)  // 添加顶部内边距给删除按钮留空间
                    .padding(.trailing, 8)  // 添加右侧内边距给删除按钮留空间
                }
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 4, y: -4)  // 调整删除按钮的位置
            }
            .frame(width: 66, height: 66)  // 增加整体框架大小以容纳删除按钮
        }
    }
    
    // 从文件路径加载图片
    private func loadImage(from path: String?) -> UIImage? {
        guard let path = path else { return nil }
        return UIImage(contentsOfFile: path)
    }
} 
