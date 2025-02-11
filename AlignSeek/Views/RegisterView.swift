import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var nickname = ""  // 添加昵称
    @State private var verificationCode = ""  // 添加验证码
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false  // 密码可见性
    @State private var isConfirmPasswordVisible = false  // 确认密码可见性
    @State private var isSendingCode = false  // 控制发送按钮状态
    @State private var countdown = 60  // 倒计时
    @State private var timer: Timer?
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showingSendError = false
    @State private var sendErrorMessage = ""
    @State private var showingRegisterError = false
    @State private var registerErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Image("icon_hksense")
                .frame(width:121, height: 24)
                .padding(.top, 30)
            Text("Create Account")
                .font(.title2)
                .bold()
            
            // 邮箱输入框
            TextField("Your Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .foregroundColor(.black)
                .padding(.horizontal)
                .frame(height: 56)  // 固定高度
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            
            // 昵称输入框
            TextField("Nickname", text: $nickname)
                .textInputAutocapitalization(.never)
                .foregroundColor(.black)
                .padding(.horizontal)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            
            // 验证码输入框和发送按钮
            HStack(spacing: 12) {
                TextField("Verification Code", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                
                Button(action: {
                    sendVerificationCode()
                }) {
                    Text(isSendingCode ? "\(countdown)s" : "Send Code")
                        .foregroundColor(.white)
                        .frame(width: 100, height: 56)
                        .background(isSendingCode ? Color.gray : Color.blue)
                        .cornerRadius(16)
                }
                .disabled(isSendingCode || !isValidEmail(email))
            }
            .padding(.horizontal)
            
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
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // 确认密码输入框
            HStack {
                if isConfirmPasswordVisible {
                    TextField("Confirm Password", text: $confirmPassword)
                        .foregroundColor(.black)
                        .padding(.leading)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .foregroundColor(.black)
                        .padding(.leading)
                }
                
                Button(action: {
                    isConfirmPasswordVisible.toggle()
                }) {
                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
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
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // 注册按钮
            Button(action: {
                register()
            }) {
                Text("Register")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!isValidInput)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .alert("发送验证码", isPresented: $showingSendError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(sendErrorMessage)
        }
        .alert("注册失败", isPresented: $showingRegisterError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(registerErrorMessage)
        }
    }
    
    private var isValidInput: Bool {
        isValidEmail(email) && 
        password.count >= 6 && 
        password == confirmPassword && 
        !verificationCode.isEmpty &&  // 添加验证码非空判断
        !nickname.isEmpty  // 同时也添加昵称非空判断
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    private func register() {
        guard isValidInput else { return }
        
        Task {
            do {
                let response = try await AuthService.shared.register(
                    email: email,
                    code: verificationCode,
                    password: password,
                    nickname: nickname
                )
                
                await MainActor.run {
                    if response.errorId == 0 {
                        // 注册成功
                        UserDefaults.standard.set(email, forKey: "userEmail")
                        isLoggedIn = true
                        dismiss()
                    } else {
                        // 注册失败
                        registerErrorMessage = "注册失败，请稍后重试"
                        showingRegisterError = true
                    }
                }
            } catch {
                // 处理网络错误
                await MainActor.run {
                    registerErrorMessage = "注册失败，请稍后重试"
                    showingRegisterError = true
                }
            }
        }
    }
    
    private func sendVerificationCode() {
        guard isValidEmail(email) else { return }
        
        Task {
            do {
                let response = try await AuthService.shared.sendVerificationCode(
                    email: email,
                    use: .register
                )
                
                await MainActor.run {
                    if response.errorId == 0 {
                        // 发送成功，开始倒计时
                        isSendingCode = true
                        countdown = 60
                        
                        // 开始倒计时
                        timer?.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            if countdown > 0 {
                                countdown -= 1
                            } else {
                                isSendingCode = false
                                timer.invalidate()
                            }
                        }
                    } else {
                        // 发送失败
                        sendErrorMessage = "发送失败，请稍后重试"
                        showingSendError = true
                    }
                }
            } catch {
                // 处理网络错误
                await MainActor.run {
                    sendErrorMessage = "发送失败，请稍后重试"
                    showingSendError = true
                }
            }
        }
    }
} 
