//
//  NeverGoneDemoApp.swift
//  NeverGoneDemo
//
//  Main app entry point with auth state routing.
//

import SwiftUI

@main
struct NeverGoneDemoApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .unknown:
                    // Loading state
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                    
                case .signedOut:
                    AuthView()
                    
                case .signedIn:
                    SessionListView(authViewModel: authViewModel)
                }
            }
            .animation(.easeInOut, value: authViewModel.authState)
        }
    }
}
