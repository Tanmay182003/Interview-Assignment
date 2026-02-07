//
//  StreamingService.swift
//  NeverGoneDemo
//
//  Service for consuming SSE streaming responses from chat_stream Edge Function.
//

import Foundation

/// Errors that can occur during streaming
enum StreamingError: LocalizedError {
    case invalidURL
    case noAccessToken
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case connectionError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid streaming URL"
        case .noAccessToken:
            return "Not authenticated"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .connectionError(let error):
            return "Connection error: \(error.localizedDescription)"
        }
    }
}

/// Service for streaming chat responses via SSE
final class StreamingService {
    
    /// Shared instance
    static let shared = StreamingService()
    
    private let decoder: JSONDecoder
    
    private init() {
        self.decoder = JSONDecoder()
    }
    
    /// Stream chat response for a given session and message
    /// - Parameters:
    ///   - sessionId: The chat session ID
    ///   - message: The user's message
    /// - Returns: An async stream of content chunks
    func streamChat(sessionId: UUID, message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await performStream(sessionId: sessionId, message: message, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func performStream(
        sessionId: UUID,
        message: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Get access token
        guard let accessToken = await SupabaseManager.shared.accessToken else {
            print("❌ DEBUG: No access token available!")
            throw StreamingError.noAccessToken
        }
        
        print("✅ DEBUG: Got access token: \(accessToken.prefix(20))...")
        
        // Build request
        var request = URLRequest(url: Config.chatStreamURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "session_id": sessionId.uuidString,
            "message": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Create streaming session
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StreamingError.connectionError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            // Read error body for debugging
            var errorBody = ""
            for try await byte in bytes {
                errorBody.append(Character(UnicodeScalar(byte)))
                if errorBody.count > 500 { break } // Limit size
            }
            print("❌ DEBUG: HTTP \(httpResponse.statusCode) Error body: \(errorBody)")
            throw StreamingError.httpError(statusCode: httpResponse.statusCode, message: errorBody.isEmpty ? nil : errorBody)
        }
        
        // Process SSE stream
        var buffer = ""
        
        for try await byte in bytes {
            // Check for cancellation
            if Task.isCancelled {
                continuation.finish()
                return
            }
            
            let char = Character(UnicodeScalar(byte))
            buffer.append(char)
            
            // SSE events are separated by double newlines
            while let eventEnd = buffer.range(of: "\n\n") {
                let eventData = String(buffer[..<eventEnd.lowerBound])
                buffer.removeSubrange(..<eventEnd.upperBound)
                
                // Parse SSE event
                if let chunk = parseSSEEvent(eventData) {
                    if chunk == "[DONE]" {
                        continuation.finish()
                        return
                    } else {
                        continuation.yield(chunk)
                    }
                }
            }
        }
        
        continuation.finish()
    }
    
    /// Parse an SSE event and extract the content
    private func parseSSEEvent(_ event: String) -> String? {
        // SSE format: "data: {...}\n" or "data: [DONE]\n"
        let lines = event.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let data = String(line.dropFirst(6))
                
                // Check for done signal
                if data == "[DONE]" {
                    return "[DONE]"
                }
                
                // Parse JSON chunk
                if let jsonData = data.data(using: .utf8),
                   let chunk = try? decoder.decode(StreamChunk.self, from: jsonData) {
                    return chunk.content
                }
            }
        }
        
        return nil
    }
}

// MARK: - Cancellable Stream Wrapper

/// Wrapper for managing a cancellable streaming task
final class StreamingTask {
    private var task: Task<Void, Never>?
    
    /// Start streaming with a handler for each chunk
    func start(
        sessionId: UUID,
        message: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        task = Task {
            do {
                for try await chunk in StreamingService.shared.streamChat(sessionId: sessionId, message: message) {
                    if Task.isCancelled { break }
                    await MainActor.run {
                        onChunk(chunk)
                    }
                }
                await MainActor.run {
                    onComplete()
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        onError(error)
                    }
                }
            }
        }
    }
    
    /// Cancel the streaming task
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    /// Check if streaming is in progress
    var isActive: Bool {
        task != nil && task?.isCancelled == false
    }
}
