import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo
                Image("HKSense")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 100)
                    .padding(.bottom, 20)
                
                Text("Log in to unlock seamless\nAI conversations.")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .padding(.bottom, 40)
                
                // 邮箱输入框
                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("baby@gmail.com").foregroundColor(.gray)
                    }
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                // 密码输入框
                SecureField("Password", text: $password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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