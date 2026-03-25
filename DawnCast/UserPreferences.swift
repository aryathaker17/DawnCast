//
//  UserPreferences.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    var userEmail: String
    var selectedTopics: [String]
    var selectedSources: [String]
    var hasCompletedOnboarding: Bool

    init(userEmail: String, selectedTopics: [String] = [], selectedSources: [String] = [], hasCompletedOnboarding: Bool = false) {
        self.userEmail = userEmail
        self.selectedTopics = selectedTopics
        self.selectedSources = selectedSources
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
