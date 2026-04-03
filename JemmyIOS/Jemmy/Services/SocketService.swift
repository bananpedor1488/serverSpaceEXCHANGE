import Foundation
import Combine

class SocketService: ObservableObject {
    static let shared = SocketService()
    @Published var messages: [ChatMessage] = []
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url = URL(string: "wss://weeky-six.vercel.app")!
    
    private init() {}
    
    func connect(userId: String) {
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        
        register(userId: userId)
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    private func register(userId: String) {
        let message = ["user_id": userId]
        send(event: "register", data: message)
    }
    
    func joinChat(chatId: String) {
        let message = ["chat_id": chatId]
        send(event: "join_chat", data: message)
    }
    
    func sendMessage(chatId: String, senderIdentityId: String, content: String) {
        let message: [String: Any] = [
            "chat_id": chatId,
            "sender_identity_id": senderIdentityId,
            "encrypted_content": content,
            "type": "text"
        ]
        send(event: "send_message", data: message)
    }
    
    private func send(event: String, data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received: \(text)")
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
}
