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
        case usernameTaken
        case userNotFound
        case wrongPassword
        case passwordTooShort
        case passwordsDoNotMatch

        var errorDescription: String? {
            switch self {
            case .usernameTaken: "That username is already taken."
            case .userNotFound: "No account found with that username."
            case .wrongPassword: "Incorrect password."
            case .passwordTooShort: "Password must be at least 6 characters."
            case .passwordsDoNotMatch: "Passwords do not match."
            }
        }
    }

    /// Creates a new account and logs the user in.
    func signUp(username: String, password: String, confirmPassword: String) throws {
        guard password.count >= 6 else { throw AuthError.passwordTooShort }
        guard password == confirmPassword else { throw AuthError.passwordsDoNotMatch }

        // Check if username already exists
        let trimmedUsername = username.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.username == trimmedUsername }
        )
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { throw AuthError.usernameTaken }

        let hash = UserAccount.hash(password: password)
        let account = UserAccount(username: trimmedUsername, passwordHash: hash)
        modelContext.insert(account)
        try modelContext.save()
        currentUser = account
    }

    /// Validates credentials and logs the user in.
    func login(username: String, password: String) throws {
        let trimmedUsername = username.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<UserAccount>(
            predicate: #Predicate { $0.username == trimmedUsername }
        )
        let results = try modelContext.fetch(descriptor)
        guard let account = results.first else { throw AuthError.userNotFound }

        let hash = UserAccount.hash(password: password)
        guard account.passwordHash == hash else { throw AuthError.wrongPassword }

        currentUser = account
    }
}
