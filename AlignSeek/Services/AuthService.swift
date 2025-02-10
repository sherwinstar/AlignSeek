import Foundation

class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://27.106.108.48/dev-api/security/v1/authentication"
    
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
} 