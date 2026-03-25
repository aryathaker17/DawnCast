//
//  AuthenticationView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignUp = false
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            HomeView()
        } else {
            ZStack {
                // Background gradient to let Liquid Glass shine
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3), .orange.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // App branding
                        VStack(spacing: 8) {
                            Image(systemName: "sun.horizon.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.orange)
                            Text("DawnCast")
                                .font(.largeTitle.bold())
                            Text(isShowingSignUp ? "Create your account" : "Welcome back")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)

                        // Login or Sign Up form
                        if isShowingSignUp {
                            SignUpFormView(
                                isAuthenticated: $isAuthenticated,
                                isShowingSignUp: $isShowingSignUp
                            )
                        } else {
                            LoginFormView(
                                isAuthenticated: $isAuthenticated,
                                isShowingSignUp: $isShowingSignUp
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isShowingSignUp)
        }
    }
}

// MARK: - Login Form

struct LoginFormView: View {
    @Binding var isAuthenticated: Bool
    @Binding var isShowingSignUp: Bool

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            // Form fields inside a glass container
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))
            }

            // Error message
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            // Log In button
            Button {
                attemptLogin()
            } label: {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .disabled(username.isEmpty || password.isEmpty)

            // Forgot Password
            Button("Forgot Password?") {
                // Placeholder for forgot password flow
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
            }

            // Switch to Sign Up
            Button {
                isShowingSignUp = true
            } label: {
                Text("Create an Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
        }
        .padding(24)
        .glassEffect(in: .rect(cornerRadius: 24))
    }

    private func attemptLogin() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both username and password."
            showError = true
            return
        }
        // Simulate successful login
        withAnimation {
            isAuthenticated = true
        }
    }
}

// MARK: - Sign Up Form

struct SignUpFormView: View {
    @Binding var isAuthenticated: Bool
    @Binding var isShowingSignUp: Bool

    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            // Form fields
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.badge.checkmark.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))
            }

            // Error message
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            // Create Account button
            Button {
                attemptSignUp()
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .disabled(username.isEmpty || password.isEmpty || confirmPassword.isEmpty)

            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
            }

            // Switch to Login
            Button {
                isShowingSignUp = false
            } label: {
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Text("Log In")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
        }
        .padding(24)
        .glassEffect(in: .rect(cornerRadius: 24))
    }

    private func attemptSignUp() {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username."
            showError = true
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            showError = true
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return
        }
        // Simulate successful sign up
        withAnimation {
            isAuthenticated = true
        }
    }
}

// MARK: - Home View (placeholder after login)

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Welcome to DawnCast")
                .font(.title2.bold())
            Text("You're logged in!")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Login") {
    AuthenticationView()
}
