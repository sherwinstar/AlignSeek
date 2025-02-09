import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false  // 密码可见性
    @State private var isConfirmPasswordVisible = false  // 确认密码可见性
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.title2)
                .bold()
                .padding(.top, 60)
            
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
    }
    
    private var isValidInput: Bool {
        isValidEmail(email) && password.count >= 6 && password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    private func register() {
        if isValidInput {
            // 保存用户信息
            UserDefaults.standard.set(email, forKey: "userEmail")
            // 设置登录状态
            isLoggedIn = true
            // 关闭注册页面
            dismiss()
        }
    }
} 
