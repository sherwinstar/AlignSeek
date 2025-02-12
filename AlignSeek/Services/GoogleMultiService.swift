import UIKit
import SwiftUI
import GoogleGenerativeAI

class GoogleMultiService {
    static let shared = GoogleMultiService()
    private init() {}
    
    // 添加一个属性来存储当前任务
    private var currentTask: Task<Void, Never>?
    private let model = GenerativeModel(name: "gemini-1.5-pro", apiKey: APIKey.default)

    func generateResponse(for prompt: String) async throws -> String {
        // 取消之前的任务（如果有）
//        currentTask?.cancel()
        
        do {
            let response = try await model.generateContent(prompt)
            
            if let text = response.text {
                return text
            } else {
                throw NSError(domain: "GoogleTextService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No text in response"])
                }
            } catch {
                print("Gemini API error: \(error)")
                throw error
            }
    }
    
    // 用于取消当前任务
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // 带有回调的版本
    func sendMessage(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 取消之前的任务
        currentTask?.cancel()
        
        // 创建新任务
        currentTask = Task {
            do {
                let response = try await generateResponse(for: prompt)
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.success(response))
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // 处理文本和图片的方法
    func generateResponse(prompt: String, image: UIImage) async throws -> String {
//        currentTask?.cancel()
        do {
            let response = try await model.generateContent(prompt, image)
            if let text = response.text {
                return text
            } else {
                throw NSError(domain: "GoogleTextService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No text in response"])
                }
            } catch {
                print("Gemini API error: \(error)")
                throw error
            }
    }
    
    // 带回调的版本
    func sendMessage(prompt: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let response = try await generateResponse(prompt: prompt, image: image)
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.success(response))
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // 处理多张图片的方法
    func generateResponse(prompt: String, images: [UIImage]) async throws -> String {
//        currentTask?.cancel()
        
        do {
            var imageArray = [any ThrowingPartsRepresentable]()
            imageArray.append(contentsOf: images)
            let response = try await model.generateContent(prompt, imageArray)
            if let text = response.text {
                return text
            } else {
                throw NSError(domain: "GoogleTextService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No text in response"])
                }
            } catch {
                print("Gemini API error: \(error)")
                throw error
            }
    }
    
    // 带回调的多图版本
    func sendMessage(prompt: String, images: [UIImage], completion: @escaping (Result<String, Error>) -> Void) {
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let response = try await generateResponse(prompt: prompt, images: images)
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.success(response))
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
}

// 错误类型
extension GoogleMultiService {
    enum ServiceError: LocalizedError {
        case noResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noResponse:
                return "No response from AI"
            case .apiError(let message):
                return "API Error: \(message)"
            }
        }
    }
}
