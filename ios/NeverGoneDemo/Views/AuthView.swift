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
            if viewModel.isPendingVerification {
                otpVerificationView
            } else {
                loginFormView
            }
        }
    }
    
    // MARK: - OTP Verification View
    
    private var otpVerificationView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)
                
                Text("Check Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("We sent an 8-digit code to\n\(viewModel.email)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // OTP input
            VStack(spacing: 16) {
                TextField("Enter Code", text: $viewModel.otpCode)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(error.contains("sent") ? .green : .red)
                        .multilineTextAlignment(.center)
                }
                
                // Verify button
                Button {
                    Task {
                        await viewModel.verifyOTP()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Verify")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.otpCode.isEmpty ? Color.gray : Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isLoading || viewModel.otpCode.isEmpty)
                
                // Resend and Cancel buttons
                HStack {
                    Button {
                        Task {
                            await viewModel.resendOTP()
                        }
                    } label: {
                        Text("Resend Code")
                            .font(.footnote)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer()
                    
                    Button {
                        viewModel.cancelVerification()
                    } label: {
                        Text("Cancel")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Login Form View
    
    private var loginFormView: some View {
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
                
                // Confirm password for sign up
                if viewModel.isSignUpMode {
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                
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

#Preview {
    AuthView()
}
