//
//  MemoryService.swift
//  NeverGoneDemo
//
//  Service for memory operations (summarize_memory Edge Function).
//

import Foundation

/// Errors that can occur during memory operations
enum MemoryError: LocalizedError {
    case noAccessToken
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "Not authenticated"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Service for memory-related operations
final class MemoryService {
    
    /// Shared instance
    static let shared = MemoryService()
    
    private let decoder: JSONDecoder
    
    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Trigger memory summarization for a chat session
    /// - Parameter sessionId: The session to summarize
    /// - Returns: The created memory
    func summarize(sessionId: UUID) async throws -> Memory {
        // Get access token
        guard let accessToken = await SupabaseManager.shared.accessToken else {
            throw MemoryError.noAccessToken
        }
        
        // Build request
        var request = URLRequest(url: Config.summarizeMemoryURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "session_id": sessionId.uuidString
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MemoryError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            let bodyString = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ DEBUG: Memory save failed. HTTP \(httpResponse.statusCode) Body: \(bodyString)")
            let errorMessage = try? decoder.decode(APIError.self, from: data).error
            throw MemoryError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Decode response
        do {
            let response = try decoder.decode(SummarizeMemoryResponse.self, from: data)
            return response.memory
        } catch {
            throw MemoryError.decodingError(error.localizedDescription)
        }
    }
    
    /// Fetch all memories for the current user
    func fetchMemories() async throws -> [Memory] {
        let response: [Memory] = try await SupabaseManager.shared
            .from("memories")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch memories for a specific session
    func fetchMemories(for sessionId: UUID) async throws -> [Memory] {
        let response: [Memory] = try await SupabaseManager.shared
            .from("memories")
            .select()
            .eq("session_id", value: sessionId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
}
