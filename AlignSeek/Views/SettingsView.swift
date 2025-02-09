import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // 这里可以添加其他设置选项
                    Section {
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("确认退出登录", isPresented: $showingLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("退出登录", role: .destructive) {
                    logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
        }
    }
    
    private func logout() {
        // 清除登录状态
        isLoggedIn = false
        // 关闭设置页面
        dismiss()
    }
} 