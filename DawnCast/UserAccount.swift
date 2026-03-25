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
    @Attribute(.unique) var username: String
    var passwordHash: String

    init(username: String, passwordHash: String) {
        self.username = username
        self.passwordHash = passwordHash
    }

    /// Hashes a plaintext password using SHA256.
    static func hash(password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
