import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var isPasswordVisible = false
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo
                
                Text("Log in to unlock seamless\nAI conversations.")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 40)
                
                // 邮箱输入框
                TextField("Your Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
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
                
                // 注册按钮
                NavigationLink(destination: RegisterView(), isActive: $showingRegister) {
                    Text("Create Account")
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 60)
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
        if isValidInput {
            // 保存用户邮箱
            UserDefaults.standard.set(email, forKey: "userEmail")
            isLoggedIn = true
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