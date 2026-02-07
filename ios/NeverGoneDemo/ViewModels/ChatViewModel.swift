//
//  ChatViewModel.swift
//  NeverGoneDemo
//
//  ViewModel for the chat screen with streaming support.
//

import Foundation

/// ViewModel for the chat screen
@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var streamingContent: String = ""
    @Published private(set) var isStreaming = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    let session: ChatSession
    private var streamingTask: StreamingTask?
    
    // MARK: - Initialization
    
    init(session: ChatSession) {
        self.session = session
    }
    
    // MARK: - Message Loading
    
    /// Fetch existing messages for the session
    func loadMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [ChatMessage] = try await SupabaseManager.shared
                .from("chat_messages")
                .select()
                .eq("session_id", value: session.id.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            messages = response
            
            // Add welcome message if this is a new chat with no messages
            if messages.isEmpty {
                let welcomeMessage = ChatMessage.local(
                    sessionId: session.id,
                    role: .assistant,
                    content: "Hi! I'm your NeverGone assistant. How can I help you today?"
                )
                messages.append(welcomeMessage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sending Messages
    
    /// Send a message and stream the response
    /// - Parameter text: The message text to send
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isStreaming else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add optimistic user message
        let userMessage = ChatMessage.local(
            sessionId: session.id,
            role: .user,
            content: trimmedText
        )
        messages.append(userMessage)
        
        // Clear any previous error
        errorMessage = nil
        
        // Start streaming
        startStreaming(message: trimmedText)
    }
    
    /// Cancel the current streaming response
    func cancelStream() {
        streamingTask?.cancel()
        streamingTask = nil
        
        // If we have partial streaming content, save it as a message
        if !streamingContent.isEmpty {
            let partialMessage = ChatMessage.local(
                sessionId: session.id,
                role: .assistant,
                content: streamingContent + " [cancelled]"
            )
            messages.append(partialMessage)
        }
        
        streamingContent = ""
        isStreaming = false
    }
    
    // MARK: - Memory
    
    /// Generate a memory summary for this session
    func generateMemory() async -> Memory? {
        isLoading = true
        errorMessage = nil
        
        do {
            let memory = try await MemoryService.shared.summarize(sessionId: session.id)
            isLoading = false
            return memory
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Private
    
    private func startStreaming(message: String) {
        isStreaming = true
        streamingContent = ""
        
        streamingTask = StreamingTask()
        streamingTask?.start(
            sessionId: session.id,
            message: message,
            onChunk: { [weak self] chunk in
                self?.streamingContent += chunk
            },
            onComplete: { [weak self] in
                self?.handleStreamComplete()
            },
            onError: { [weak self] error in
                self?.handleStreamError(error)
            }
        )
    }
    
    private func handleStreamComplete() {
        // Add the complete assistant message
        if !streamingContent.isEmpty {
            let assistantMessage = ChatMessage.local(
                sessionId: session.id,
                role: .assistant,
                content: streamingContent.trimmingCharacters(in: .whitespaces)
            )
            messages.append(assistantMessage)
        }
        
        // Reset state
        streamingContent = ""
        isStreaming = false
        streamingTask = nil
    }
    
    private func handleStreamError(_ error: Error) {
        errorMessage = error.localizedDescription
        
        // If we have partial content, show it with error indicator
        if !streamingContent.isEmpty {
            let partialMessage = ChatMessage.local(
                sessionId: session.id,
                role: .assistant,
                content: streamingContent + " [error]"
            )
            messages.append(partialMessage)
        }
        
        streamingContent = ""
        isStreaming = false
        streamingTask = nil
    }
}
