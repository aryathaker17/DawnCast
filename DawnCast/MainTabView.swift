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
    @State var country: String
    let loggedInEmail: String

    @State private var selectedTab: AppTab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Summary", systemImage: "doc.text", value: .summary) {
                NavigationStack {
                    SummaryView(
                        categories: categories,
                        sources: sources,
                        country: country,
                        selectedTab: $selectedTab
                    )
                }
            }

            Tab("Feed", systemImage: "newspaper", value: .feed) {
                NavigationStack {
                    NewsFeedView(
                        isAuthenticated: $isAuthenticated,
                        categories: categories,
                        sources: sources,
                        country: country
                    )
                    .id(categories.hashValue ^ sources.hashValue ^ country.hashValue)
                }
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack {
                    ProfileView(
                        isAuthenticated: $isAuthenticated,
                        loggedInEmail: loggedInEmail,
                        categories: $categories,
                        sources: $sources,
                        country: $country
                    )
                }
            }
        }
        .tint(.orange)
    }
}
