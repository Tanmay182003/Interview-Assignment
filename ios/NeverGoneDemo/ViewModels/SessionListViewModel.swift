//
//  SessionListViewModel.swift
//  NeverGoneDemo
//
//  ViewModel for managing chat sessions.
//

import Foundation

/// ViewModel for the session list screen
@MainActor
final class SessionListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Actions
    
    /// Fetch all chat sessions for the current user
    func fetchSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [ChatSession] = try await SupabaseManager.shared
                .from("chat_sessions")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            sessions = response
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Create a new chat session
    /// - Parameter title: Optional title for the session
    /// - Returns: The created session
    @discardableResult
    func createSession(title: String = "New Chat") async -> ChatSession? {
        guard let userId = await SupabaseManager.shared.currentUserId else {
            errorMessage = "Not authenticated"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newSession: ChatSession = try await SupabaseManager.shared
                .from("chat_sessions")
                .insert([
                    "user_id": userId.uuidString,
                    "title": title
                ])
                .select()
                .single()
                .execute()
                .value
            
            // Add to beginning of list
            sessions.insert(newSession, at: 0)
            isLoading = false
            return newSession
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    /// Delete a chat session
    /// - Parameter session: The session to delete
    func deleteSession(_ session: ChatSession) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared
                .from("chat_sessions")
                .delete()
                .eq("id", value: session.id.uuidString)
                .execute()
            
            // Remove from list
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Update session title
    func updateSessionTitle(_ session: ChatSession, newTitle: String) async {
        guard !newTitle.isEmpty else { return }
        
        do {
            try await SupabaseManager.shared
                .from("chat_sessions")
                .update(["title": newTitle])
                .eq("id", value: session.id.uuidString)
                .execute()
            
            // Update local list
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index].title = newTitle
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
