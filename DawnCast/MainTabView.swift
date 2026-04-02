//
//  MainTabView.swift
//  DawnCast
//

import SwiftUI

enum AppTab: Hashable {
    case summary
    case feed
    case profile
}

struct MainTabView: View {
    @Binding var isAuthenticated: Bool
    @State var categories: [String]
    @State var sources: [String]
    let loggedInEmail: String

    @State private var selectedTab: AppTab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Summary", systemImage: "doc.text", value: .summary) {
                NavigationStack {
                    SummaryView()
                }
            }

            Tab("Feed", systemImage: "newspaper", value: .feed) {
                NavigationStack {
                    NewsFeedView(
                        isAuthenticated: $isAuthenticated,
                        categories: categories,
                        sources: sources
                    )
                    .id(categories.hashValue ^ sources.hashValue)
                }
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack {
                    ProfileView(
                        isAuthenticated: $isAuthenticated,
                        loggedInEmail: loggedInEmail,
                        categories: $categories,
                        sources: $sources
                    )
                }
            }
        }
        .tint(.orange)
    }
}
