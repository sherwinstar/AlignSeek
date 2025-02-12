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
                    Text("Sign Out")
                        .foregroundColor(Color(hex: "4E5969"))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "D6E1EF"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "4E5969"), lineWidth: 1)
                )
                .padding(.horizontal, 22)
                .padding(.bottom)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.75)
        .background(Color(UIColor.systemBackground))
        .alert("Logout ?", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out?\n You'll need to log in again to access your account.")
        }
    }
    
    private func logout() {
        isLoggedIn = false
        isPresented = false
    }
}
