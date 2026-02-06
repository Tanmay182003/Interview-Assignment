//
//  SessionListView.swift
//  NeverGoneDemo
//
//  View for listing and managing chat sessions.
//

import SwiftUI

/// Session list screen
struct SessionListView: View {
    @StateObject private var viewModel = SessionListViewModel()
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var showingNewChatSheet = false
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("Loading sessions...")
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            if let session = await viewModel.createSession() {
                                selectedSession = session
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sign Out") {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                ChatView(session: session)
            }
            .refreshable {
                await viewModel.fetchSessions()
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
        }
        .task {
            await viewModel.fetchSessions()
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Chats", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a new conversation to get started.")
        } actions: {
            Button("New Chat") {
                Task {
                    if let session = await viewModel.createSession() {
                        selectedSession = session
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var sessionList: some View {
        List {
            ForEach(viewModel.sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    SessionRow(session: session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteSession(session)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionListView(authViewModel: AuthViewModel())
}
