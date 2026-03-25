//
//  AccountManager.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import Foundation
import SwiftData

@Observable
final class AccountManager {
    private let modelContext: ModelContext

    /// The currently logged-in user, if any.
    var currentUser: UserAccount?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    enum AuthError: LocalizedError {
        case emailAlreadyExists
        case userNotFound
        case wrongPassword
        case passwordTooShort
        case passwordsDoNotMatch
        case invalidEmail

        var errorDescription: String? {
            switch self {
            case .emailAlreadyExists: "An account with that email already exists."
            case .userNotFound: "No account found with that email."
            case .wrongPassword: "Incorrect password."
            case .passwordTooShort: "Password must be at least 6 characters."
            case .passwordsDoNotMatch: "Passwords do not match."
            case .invalidEmail: "Please enter a valid email address."
            }
        }
    }

    /// Creates a new account and logs the user in.
    func signUp(firstName: String, lastName: String, email: String, password: String, confirmPassword: String) throws {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.passwordTooShort }
        guard password == confirmPassword else { throw AuthError.passwordsDoNotMatch }

        // Check if an account with this email already exists
        let allAccounts = try modelContext.fetch(FetchDescriptor<UserAccount>())
        print("[SignUp] Existing accounts in DB: \(allAccounts.count)")
        for acct in allAccounts {
            print("[SignUp]   - email: '\(acct.email)'")
        }
        if allAccounts.contains(where: { $0.email == trimmedEmail }) {
            throw AuthError.emailAlreadyExists
        }

        let hash = UserAccount.hash(password: password)
        let account = UserAccount(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: trimmedEmail,
            passwordHash: hash
        )
        modelContext.insert(account)
        try modelContext.save()
        print("[SignUp] Account saved for email: '\(trimmedEmail)'")

        // Verify it was saved
        let verifyAccounts = try modelContext.fetch(FetchDescriptor<UserAccount>())
        print("[SignUp] Accounts after save: \(verifyAccounts.count)")

        currentUser = account
    }

    /// Validates credentials and logs the user in.
    func login(email: String, password: String) throws {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        print("[Login] Attempting login with email: '\(trimmedEmail)'")
        let allAccounts = try modelContext.fetch(FetchDescriptor<UserAccount>())
        print("[Login] Accounts in DB: \(allAccounts.count)")
        for acct in allAccounts {
            print("[Login]   - email: '\(acct.email)'")
        }
        guard let account = allAccounts.first(where: { $0.email == trimmedEmail }) else {
            print("[Login] No match found for '\(trimmedEmail)'")
            throw AuthError.userNotFound
        }

        let hash = UserAccount.hash(password: password)
        guard account.passwordHash == hash else { throw AuthError.wrongPassword }

        print("[Login] Login successful for '\(trimmedEmail)'")
        currentUser = account
    }
}
