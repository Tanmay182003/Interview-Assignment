//
//  Models.swift
//  NeverGoneDemo
//
//  Data models matching the Supabase database schema.
//

import Foundation

// MARK: - Message Role

/// Role of a chat message sender
enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
}

// MARK: - Chat Session

/// Represents a chat conversation
struct ChatSession: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Chat Message

/// Individual message within a chat session
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionId: UUID
    let role: MessageRole
    var content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role
        case content
        case createdAt = "created_at"
    }
    
    /// Create a local message (before server persistence)
    static func local(sessionId: UUID, role: MessageRole, content: String) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            sessionId: sessionId,
            role: role,
            content: content,
            createdAt: Date()
        )
    }
}

// MARK: - Memory

/// Long-term memory summary from a chat session
struct Memory: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let sessionId: UUID?
    let summary: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case summary
        case createdAt = "created_at"
    }
}

// MARK: - Profile

/// User profile data
struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String?
    var displayName: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - API Response Types

/// Response from chat_stream SSE chunks
struct StreamChunk: Codable {
    let content: String
}

/// Response from summarize_memory endpoint
struct SummarizeMemoryResponse: Codable {
    let success: Bool
    let memory: Memory
}

/// Error response from API
struct APIError: Codable, Error, LocalizedError {
    let error: String
    
    var errorDescription: String? { error }
}
