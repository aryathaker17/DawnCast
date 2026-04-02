//
//  AuthenticationView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI
import SwiftData

struct AuthenticationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingSignUp = false
    @State private var isAuthenticated = false
    @State private var loggedInEmail = ""

    var body: some View {
        if isAuthenticated {
            PostAuthFlow(isAuthenticated: $isAuthenticated, loggedInEmail: loggedInEmail, modelContext: modelContext)
        } else {
            ZStack {
                // Dark background
                Color(red: 0.02, green: 0.02, blue: 0.04)
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
                                .foregroundStyle(.white)
                            Text(isShowingSignUp ? "Create your account" : "The news, before the noise.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 60)

                        // Login or Sign Up form
                        if isShowingSignUp {
                            SignUpFormView(
                                isAuthenticated: $isAuthenticated,
                                isShowingSignUp: $isShowingSignUp,
                                loggedInEmail: $loggedInEmail,
                                modelContext: modelContext
                            )
                        } else {
                            LoginFormView(
                                isAuthenticated: $isAuthenticated,
                                isShowingSignUp: $isShowingSignUp,
                                loggedInEmail: $loggedInEmail,
                                modelContext: modelContext
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
    @Binding var loggedInEmail: String
    var modelContext: ModelContext

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            // Form fields inside a glass container
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .textContentType(.oneTimeCode)
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
            .disabled(email.isEmpty || password.isEmpty)

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
        showError = false
        let manager = AccountManager(modelContext: modelContext)
        do {
            try manager.login(email: email, password: password)
            loggedInEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            withAnimation {
                isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Sign Up Form

struct SignUpFormView: View {
    @Binding var isAuthenticated: Bool
    @Binding var isShowingSignUp: Bool
    @Binding var loggedInEmail: String
    var modelContext: ModelContext

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
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
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .textContentType(.oneTimeCode)
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 12))

                HStack {
                    Image(systemName: "lock.badge.checkmark.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.oneTimeCode)
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
            .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)

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
        showError = false
        let manager = AccountManager(modelContext: modelContext)
        do {
            try manager.signUp(firstName: firstName, lastName: lastName, email: email, password: password, confirmPassword: confirmPassword)
            loggedInEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            withAnimation {
                isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Post-Auth Flow

struct PostAuthFlow: View {
    @Binding var isAuthenticated: Bool
    let loggedInEmail: String
    var modelContext: ModelContext

    @State private var userPrefs: UserPreferences?
    @State private var isLoaded = false
    @State private var onboardingComplete = false

    var body: some View {
        Group {
            if !isLoaded {
                ZStack {
                    Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            } else if let prefs = userPrefs, prefs.hasCompletedOnboarding {
                // User already onboarded — show main tab interface
                let _ = print("[PostAuthFlow] Rendering MainTabView with \(prefs.selectedTopics.count) topics, \(prefs.selectedSources.count) sources")
                MainTabView(
                    isAuthenticated: $isAuthenticated,
                    categories: prefs.selectedTopics,
                    sources: prefs.selectedSources,
                    loggedInEmail: loggedInEmail
                )
            } else {
                let _ = print("[PostAuthFlow] Rendering OnboardingFlow (userPrefs is \(userPrefs == nil ? "nil" : "present, onboarded=\(userPrefs!.hasCompletedOnboarding)"))")
                // Show onboarding
                OnboardingFlow(
                    isAuthenticated: $isAuthenticated,
                    loggedInEmail: loggedInEmail,
                    modelContext: modelContext,
                    onboardingComplete: $onboardingComplete
                )
            }
        }
        .task {
            loadPreferences()
        }
        .onChange(of: onboardingComplete) {
            if onboardingComplete {
                print("[PostAuthFlow] onboardingComplete changed to true, reloading prefs")
                loadPreferences()
            }
        }
    }

    private func loadPreferences() {
        let email = loggedInEmail
        print("[PostAuthFlow] Loading preferences for email: '\(email)'")
        let allPrefs = (try? modelContext.fetch(FetchDescriptor<UserPreferences>())) ?? []
        print("[PostAuthFlow] Found \(allPrefs.count) total preferences records")
        for p in allPrefs {
            print("[PostAuthFlow]   - email: '\(p.userEmail)', onboarded: \(p.hasCompletedOnboarding), topics: \(p.selectedTopics.count), sources: \(p.selectedSources.count)")
        }
        userPrefs = allPrefs.first(where: { $0.userEmail == email })
        print("[PostAuthFlow] Matched prefs: \(userPrefs != nil), isLoaded will be true")
        if let prefs = userPrefs {
            print("[PostAuthFlow] Will show feed with topics: \(prefs.selectedTopics), sources: \(prefs.selectedSources)")
        }
        isLoaded = true
    }
}

// MARK: - Onboarding Flow

struct OnboardingFlow: View {
    @Binding var isAuthenticated: Bool
    let loggedInEmail: String
    var modelContext: ModelContext
    @Binding var onboardingComplete: Bool

    @State private var currentStep = 0
    @State private var selectedTopics: Set<String> = []
    @State private var selectedSources: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04)
                    .ignoresSafeArea()

                switch currentStep {
                case 0:
                    // Welcome screen
                    welcomeView
                case 1:
                    // Topic selection
                    TopicSelectionView(selectedTopics: $selectedTopics)
                case 2:
                    // Source selection
                    SourceSelectionView(selectedTopics: selectedTopics, selectedSources: $selectedSources)
                default:
                    EmptyView()
                }

                // Bottom navigation bar
                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log Out") {
                        withAnimation {
                            isAuthenticated = false
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("Welcome to DawnCast")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Let's personalize your news experience")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step == currentStep ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            // Next / Done button
            Button {
                advanceStep()
            } label: {
                Text(currentStep == 2 ? "Done" : "Next")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .disabled(isNextDisabled)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var isNextDisabled: Bool {
        switch currentStep {
        case 1: return selectedTopics.isEmpty
        case 2: return selectedSources.isEmpty
        default: return false
        }
    }

    private func advanceStep() {
        if currentStep < 2 {
            withAnimation {
                currentStep += 1
            }
        } else {
            savePreferencesAndFinish()
        }
    }

    private func savePreferencesAndFinish() {
        print("[Onboarding] Saving preferences - topics: \(selectedTopics), sources: \(selectedSources)")
        let prefs = UserPreferences(
            userEmail: loggedInEmail,
            selectedTopics: Array(selectedTopics),
            selectedSources: Array(selectedSources),
            hasCompletedOnboarding: true
        )
        modelContext.insert(prefs)
        try? modelContext.save()

        onboardingComplete = true
    }
}

#Preview("Login") {
    AuthenticationView()
}
