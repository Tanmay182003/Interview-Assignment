//
//  AuthView.swift
//  NeverGoneDemo
//
//  Authentication view for sign in and sign up.
//

import SwiftUI

/// Authentication screen
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo / Title
                VStack(spacing: 8) {
                    Image(systemName: "message.badge.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.primary)
                    
                    Text("NeverGone")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your AI companion with memory")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                    
                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Primary action button
                    Button {
                        Task {
                            if viewModel.isSignUpMode {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Toggle mode
                    Button {
                        viewModel.toggleMode()
                    } label: {
                        Text(viewModel.isSignUpMode
                             ? "Already have an account? Sign In"
                             : "Don't have an account? Sign Up")
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AuthView()
}
