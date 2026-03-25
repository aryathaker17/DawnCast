//
//  UserAccount.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import Foundation
import SwiftData
import CryptoKit

@Model
final class UserAccount {
    var firstName: String
    var lastName: String
    @Attribute(.unique) var email: String
    var passwordHash: String

    init(firstName: String, lastName: String, email: String, passwordHash: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
    }

    /// Hashes a plaintext password using SHA256.
    static func hash(password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
