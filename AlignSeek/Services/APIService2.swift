import Foundation
import UIKit
import SwiftUI

class APIService2 {
    static let shared = APIService2()
    private let baseURL = "http://27.106.108.48:8084/v2/chat/completions"
    
    private init() {}
    
    // 添加一个属性来存储当前任务
    private var currentTask: URLSessionDataTask?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct RequestBody: Codable {
        let messages: [Message]
    }
    
    func sendMessage(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 如果有正在进行的任务，先取消它
        currentTask?.cancel()
        
        let item = Message(role: "user", content: text)
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
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer { self?.currentTask = nil }
            
            if let error = error as NSError? {
                // 检查是否是取消操作
                if error.code == NSURLErrorCancelled {
                    return // 如果是取消操作，直接返回
                }
                completion(.failure(error))
                return
            }
            
            // 处理响应
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            if let data = responseString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               var content = message["content"] as? String {
                
                // 移除 </think> 标签及之前的内容
                if let range = content.range(of: "</think>") {
                    content = String(content[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                completion(.success(content))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
            }
        }
        
        currentTask?.resume()
    }
    
    // 添加取消方法
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
}
