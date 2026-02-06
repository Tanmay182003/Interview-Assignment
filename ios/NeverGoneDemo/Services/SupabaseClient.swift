//
//  SupabaseClient.swift
//  NeverGoneDemo
//
//  Singleton Supabase client configuration.
//

import Foundation
import Supabase

/// Shared Supabase client instance
final class SupabaseManager {
    
    /// Shared singleton instance
    static let shared = SupabaseManager()
    
    /// The Supabase client
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(Config.supabaseURL)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    // MARK: - Convenience Accessors
    
    /// Auth client for authentication operations
    var auth: AuthClient {
        client.auth
    }
    
    /// Database client for Postgres operations
    var database: PostgrestClient {
        client.database
    }
    
    // MARK: - Current User
    
    /// Get the current authenticated user's ID
    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
    
    /// Get the current session's access token
    var accessToken: String? {
        get async {
            try? await client.auth.session.accessToken
        }
    }
}
