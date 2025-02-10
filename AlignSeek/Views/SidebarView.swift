import SwiftUI

struct SidebarView: View {
    @Binding var isPresented: Bool
    @Binding var currentSession: ChatSession?
    var onSessionSelected: ((ChatSession) -> Void)?
    @State private var searchText = ""
    @State private var showingLogoutAlert = false
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    // 获取当前用户的所有会话
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ChatSession.time, ascending: false)],
        predicate: NSPredicate(format: "email == %@", UserDefaults.standard.string(forKey: "userEmail") ?? "")
    ) private var sessions: FetchedResults<ChatSession>
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索", text: $searchText)
            }
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding()
            
            // 会话列表
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sessions) { session in
                        Button(action: {
                            currentSession = session
                            onSessionSelected?(session)
                            isPresented = false
                        }) {
                            HStack {
                                Text(session.title ?? "New Chat")
                                    .lineLimit(1)
                                Spacer()
                                Image("icon_right_arrow")  // 使用自定义图片
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // 底部登出按钮
            Button(action: {
                showingLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("退出登录")
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.75)
        .background(Color(UIColor.systemBackground))
        .alert("确认退出登录", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出登录", role: .destructive) {
                logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
    
    private func logout() {
        isLoggedIn = false
        isPresented = false
    }
} 
