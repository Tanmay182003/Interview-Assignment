//
//  Config.swift
//  NeverGoneDemo
//
//  Configuration for Supabase connection.
//  Update these values with your local Supabase instance.
//

import Foundation

/// App configuration - update these for your local setup
enum Config {
    // MARK: - Supabase Configuration
    
    /// Supabase Cloud Project URL
    /// Project: wiuyymmcusibwqoosnqo
    static let supabaseURL = "https://wiuyymmcusibwqoosnqo.supabase.co"
    
    /// Supabase anonymous key
    /// Get from: Dashboard → Settings → API → anon public key
    /// This is safe to include in client apps - RLS protects data
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndpdXl5bW1jdXNpYndxb29zbnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzOTI3ODksImV4cCI6MjA4NTk2ODc4OX0.VHEe_4VHCjNrEzQa_vELjdNqHfPonsPg3W24rbr9DPk"
    
    // MARK: - Edge Functions
    
    /// Chat stream function URL
    static var chatStreamURL: URL {
        URL(string: "\(supabaseURL)/functions/v1/chat_stream")!
    }
    
    /// Summarize memory function URL
    static var summarizeMemoryURL: URL {
        URL(string: "\(supabaseURL)/functions/v1/summarize_memory")!
    }
}
