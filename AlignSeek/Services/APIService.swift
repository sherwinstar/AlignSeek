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
    
    func sendMessage(_ text: String, message: ChatMessage? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        var contents: [Content] = [
            Content(type: "text", text: text, image_base64: nil)
        ]
        
        // 如果有消息对象，处理其中的附件
        if let message = message, let mediaUrls = message.medias as? [String] {
            for mediaPath in mediaUrls {
                let fullPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(mediaPath).path
                if let image = UIImage(contentsOfFile: fullPath) {
                    if let base64String = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
                        contents.append(Content(type: "image", text: nil, image_base64: base64String))
                    }
                }
            }
        }
        
        let item = Message(role: "user", content: contents)
        let requestBody = RequestBody(messages: [item])
        
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
            
            // 处理响应
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
                let lines = responseString.components(separatedBy: "\n")
                var aiResponse = ""
                
                for line in lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6))
                        if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                            continue
                        }
                        
                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let text = json["text"] as? String {
                            aiResponse += text
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
