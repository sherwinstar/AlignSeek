import SwiftUI
import Photos
import AVFoundation

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

// 自定义 TextView 组件
struct AdaptiveTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .white
        textView.isScrollEnabled = false
        textView.text = text
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
        if uiView.window != nil, !context.coordinator.didSetupInitialHeight {
            context.coordinator.didSetupInitialHeight = true
            DispatchQueue.main.async {
                self.height = max(44, uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude)).height)
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AdaptiveTextView
        var didSetupInitialHeight = false
        
        init(_ parent: AdaptiveTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            DispatchQueue.main.async {
                self.parent.height = min(max(44, size.height), 120)
            }
        }
    }
}

// 添加新的弹出菜单视图
struct PlusMenuView: View {
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingFileImporter = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertType = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                checkPhotoLibraryPermission()
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("附加照片")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "photo")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            Button(action: {
                checkCameraPermission()
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("拍照")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "camera")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            Button(action: {
                showingFileImporter = true
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("附加文件")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "folder")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.4)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .pdf, .text],
            allowsMultipleSelection: false
        ) { result in
            do {
                let fileUrl = try result.get().first
                // 处理选中的文件
                print("Selected file: \(fileUrl?.lastPathComponent ?? "")")
            } catch {
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .alert(permissionAlertType, isPresented: $showingPermissionAlert) {
            Button("设置", role: .none) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(getPermissionMessage())
        }
    }
    
    private func getPermissionMessage() -> String {
        switch permissionAlertType {
        case "相机权限":
            return "需要相机权限才能拍照，请在设置中开启。"
        case "相册权限":
            return "需要相册权限才能选择照片，请在设置中开启。"
        default:
            return ""
        }
    }
    
    private func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            showingImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showingImagePicker = true
                    }
                }
            }
        default:
            permissionAlertType = "相册权限"
            showingPermissionAlert = true
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    }
                }
            }
        default:
            permissionAlertType = "相机权限"
            showingPermissionAlert = true
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // 处理选中的图片
                print("Selected image size: \(image.size)")
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

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
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 0)
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30
                        )
                        .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
                    )
                    .focused($isFocused)
                    
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
                            Button(action: {}) {
                                Image(systemName: "mic")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                            }
                            
                            Button(action: {
                                if !inputMessage.isEmpty {
                                    sendMessage()
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
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingPlusMenu)
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

// 自定义圆角形状
struct RoundedCorners: View {
    var color: Color
    var tl: CGFloat = 0.0 // top-left radius
    var tr: CGFloat = 0.0 // top-right radius
    var bl: CGFloat = 0.0 // bottom-left radius
    var br: CGFloat = 0.0 // bottom-right radius
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let w = geometry.size.width
                let h = geometry.size.height
                
                // 确保每个角的半径不超过宽度/高度的一半
                let tr = min(min(self.tr, h/2), w/2)
                let tl = min(min(self.tl, h/2), w/2)
                let bl = min(min(self.bl, h/2), w/2)
                let br = min(min(self.br, h/2), w/2)
                
                path.move(to: CGPoint(x: w / 2.0, y: 0))
                path.addLine(to: CGPoint(x: w - tr, y: 0))
                path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                          startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
                path.addLine(to: CGPoint(x: w, y: h - br))
                path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                          startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
                path.addLine(to: CGPoint(x: bl, y: h))
                path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                          startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
                path.addLine(to: CGPoint(x: 0, y: tl))
                path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                          startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
                path.closeSubpath()
            }
            .fill(self.color)
        }
    }
}

// 添加自定义 UIViewRepresentable 来实现模糊效果
struct TransparentBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // 不需要更新
    }
} 
