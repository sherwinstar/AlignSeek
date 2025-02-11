import Foundation

// 添加验证码用途枚举
enum VerificationUse: Int {
    case register = 1
    case resetPassword = 2
}

struct RegisterRequest: Codable {
    let emailAddress: String
    let verificationCode: String
    let request: RegisterUserRequest
    
    struct RegisterUserRequest: Codable {
        let password: String
        let nickname: String
    }
}

class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://27.106.108.48/dev-api/security/v1/authentication"
    private let verificationURL = "http://27.106.108.48:8080/dev-api/security/v1/verifications/email"
    private let registerURL = "http://27.106.108.48:8080/dev-api/security/v1/users/email"
    
    private init() {}
    
    struct AuthResponse: Codable {
        let errorId: Int
        let errorMessage: String
        let data: UserData?
        
        struct UserData: Codable {
            let id: String
            let username: String
            let nickname: String
            let avatarUrl: String?
            let emailAddress: String
            let phoneNumber: String
        }
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 构建请求体
        let body = "username=\(email)&password=\(password)"
        let bodyData = body.data(using: .utf8)
        
        // 创建 POST 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        return response
    }
    
    func sendVerificationCode(email: String, use: VerificationUse) async throws -> AuthResponse {
        guard var urlComponents = URLComponents(string: verificationURL) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 添加查询参数
        urlComponents.queryItems = [
            URLQueryItem(name: "recipientEmailAddress", value: email),
            URLQueryItem(name: "use", value: String(use.rawValue))
        ]
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        return response
    }
    
    func register(email: String, code: String, password: String, nickname: String) async throws -> AuthResponse {
        guard let url = URL(string: registerURL) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 构建请求体
        let registerRequest = RegisterRequest(
            emailAddress: email,
            verificationCode: code,
            request: RegisterRequest.RegisterUserRequest(
                password: password,
                nickname: nickname
            )
        )
        
        // 创建 POST 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(registerRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        return response
    }
} 