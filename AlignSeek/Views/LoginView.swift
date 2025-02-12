import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var isPasswordVisible = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Logo
                Image("icon_hksense")
                    .frame(width:121, height: 24)
                Text("Log in to unlock seamless AI conversations.")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 24)
                    .padding(.top, 16)
                Divider().background(Color(hex: 0x1C1C1C, alpha: 0.1))
                    .padding(.horizontal)
                // 邮箱输入框
                TextField("Your Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: 0x86909C), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                // 密码输入框
                HStack {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .foregroundColor(.black)
                            .padding(.leading)
                    } else {
                        SecureField("Password", text: $password)
                            .foregroundColor(.black)
                            .padding(.leading)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(Color(.systemGray3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: 0x86909C), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // 登录按钮
                Button(action: {
                    login()
                }) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.blue : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!isValidInput)
                .padding(.horizontal)
                .padding(.top, 18)
                
                // 注册按钮
                NavigationLink(destination: RegisterView(), isActive: $showingRegister) {
                    Text("Create Account")
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 60)
            .alert("登录失败", isPresented: $showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // 预热网络连接
            let url = URL(string: "https://www.apple.com")!
            URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
        }
    }
    
    private var isValidInput: Bool {
        isValidEmail(email) && password.count >= 6
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    private func login() {
        guard isValidInput else { return }
        
        // 开始异步登录
        Task {
            do {
                let response = try await AuthService.shared.login(email: email, password: password)
                
                // 在主线程更新 UI
                await MainActor.run {
                    if response.errorId == 0 {
                        // 登录成功
                        UserDefaults.standard.set(email, forKey: "userEmail")
                        isLoggedIn = true
                    } else {
                        // 登录失败，显示错误信息
                        errorMessage = "用户名或密码错误，请重试"
                        showingError = true
                    }
                }
            } catch {
                // 处理网络错误等
                await MainActor.run {
                    errorMessage = "登录失败，请稍后重试"
                    showingError = true
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 
