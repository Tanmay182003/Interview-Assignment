//
//  ChatView.swift
//  NeverGoneDemo
//
//  Chat screen with streaming message display.
//

import SwiftUI

/// Chat screen
struct ChatView: View {
    let session: ChatSession
    
    @StateObject private var viewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    init(session: ChatSession) {
        self.session = session
        self._viewModel = StateObject(wrappedValue: ChatViewModel(session: session))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Streaming message
                        if viewModel.isStreaming && !viewModel.streamingContent.isEmpty {
                            StreamingBubble(content: viewModel.streamingContent)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.streamingContent) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            Divider()
            
            // Input area
            inputArea
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            if let memory = await viewModel.generateMemory() {
                                print("Memory created: \(memory.summary)")
                            }
                        }
                    } label: {
                        Label("Save Memory", systemImage: "brain")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadMessages()
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .disabled(viewModel.isStreaming)
                .onSubmit {
                    sendMessage()
                }
            
            // Send or Cancel button
            if viewModel.isStreaming {
                Button {
                    viewModel.cancelStream()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? .gray : .primary)
                }
                .disabled(inputText.isEmpty)
            }
        }
        .padding()
        .background(.bar)
    }
    
    // MARK: - Helpers
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        viewModel.sendMessage(text)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if viewModel.isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var bubbleColor: Color {
        message.role == .user ? .black : Color(.systemGray5)
    }
}

// MARK: - Streaming Bubble

struct StreamingBubble: View {
    let content: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(content)
                    
                    // Typing indicator
                    TypingIndicator()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: 280, alignment: .leading)
            
            Spacer()
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0.0
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(opacity(for: index))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                phase = 1.0
            }
        }
    }
    
    private func opacity(for index: Int) -> Double {
        let offset = Double(index) / 3.0
        let value = sin((phase + offset) * .pi * 2)
        return 0.3 + (value + 1) * 0.35
    }
}

#Preview {
    NavigationStack {
        ChatView(session: ChatSession(
            id: UUID(),
            userId: UUID(),
            title: "Test Chat",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
