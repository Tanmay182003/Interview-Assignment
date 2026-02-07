//
//  AuthViewModel.swift
//  NeverGoneDemo
//
//  ViewModel for authentication operations.
//

import Foundation
import Supabase

/// Authentication state
enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(userId: UUID)
}

/// ViewModel for authentication
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Form State
    
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isSignUpMode = false
    
    // MARK: - Private
    
    private var authStateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in SupabaseManager.shared.auth.authStateChanges {
                guard !Task.isCancelled else { break }
                
                switch event {
                case .initialSession:
                    if let userId = session?.user.id {
                        self.authState = .signedIn(userId: userId)
                    } else {
                        self.authState = .signedOut
                    }
                    
                case .signedIn:
                    if let userId = session?.user.id {
                        self.authState = .signedIn(userId: userId)
                    }
                    
                case .signedOut:
                    self.authState = .signedOut
                    
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Sign up with email and password
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.auth.signUp(
                email: email,
                password: password
            )
            // Clear form on success
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign in with email and password
    func signIn() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.auth.signIn(
                email: email,
                password: password
            )
            // Clear form on success
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign out the current user
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
    }
    
    // MARK: - Helpers
    
    private func validateInput() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        // Validate confirm password for sign up
        if isSignUpMode {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                return false
            }
        }
        
        return true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
    }
}
