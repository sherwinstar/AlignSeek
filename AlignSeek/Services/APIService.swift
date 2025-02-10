import Foundation
import UIKit
import SwiftUI

class APIService {
    static let shared = APIService()
    private let baseURL = "http://27.106.108.48:8084/v1/chat/completions"
    
    private init() {}
    
    struct Message: Codable {
        let role: String
        let content: [Content]
    }
    
    struct Content: Codable {
        let type: String
        let text: String?
        let image_base64: String?
        
        enum CodingKeys: String, CodingKey {
            case type
            case text
            case image_base64 = "image_base64"
        }
    }
    
    struct RequestBody: Codable {
        let messages: [Message]
    }
    
    func sendMessage(_ text: String, image: UIImage? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        var contents: [Content] = [
            Content(type: "text", text: text, image_base64: nil)
        ]
        
        if let image = image {
            if let base64String = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
                contents.append(Content(type: "image", text: nil, image_base64: base64String))
            }
        }
        
        let message = Message(role: "user", content: contents)
        let requestBody = RequestBody(messages: [message])
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            // 处理 SSE 响应
            let lines = responseString.components(separatedBy: "\n")
            var aiResponse = ""
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let delta = firstChoice["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        aiResponse += content
                    }
                }
            }
            
            completion(.success(aiResponse))
        }
        
        task.resume()
    }
}

extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
} 