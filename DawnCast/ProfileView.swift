//
//  ProfileView.swift
//  DawnCast
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    let loggedInEmail: String
    @Binding var categories: [String]
    @Binding var sources: [String]

    @Environment(\.modelContext) private var modelContext

    // Local editing state
    @State private var editingTopics: Set<String> = []
    @State private var editingSources: Set<String> = []
    @State private var originalTopics: Set<String> = []

    // Sheet presentation
    @State private var showTopicEditor = false
    @State private var showSourceEditor = false

    // Tracks whether topics were just changed (forces source re-selection)
    @State private var topicsDidChange = false

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.orange)

                    Text(loggedInEmail)
                        .font(.headline)
                        .foregroundStyle(.white)

                    // Topics section
                    preferenceSectionView(
                        title: "Your Topics",
                        items: categories.map { $0.capitalized },
                        editAction: { startEditingTopics() }
                    )

                    // Sources section
                    preferenceSectionView(
                        title: "Your Sources",
                        items: sources,
                        editAction: { startEditingSources() }
                    )

                    Spacer(minLength: 40)

                    // Log Out
                    Button {
                        withAnimation { isAuthenticated = false }
                    } label: {
                        Text("Log Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .padding(.top, 40)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            editingTopics = Set(categories)
            editingSources = Set(sources)
            originalTopics = Set(categories)
        }
        .sheet(isPresented: $showTopicEditor, onDismiss: onTopicEditorDismiss) {
            NavigationStack {
                TopicSelectionView(selectedTopics: $editingTopics)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTopicEditor = false }
                                .foregroundStyle(.orange)
                        }
                    }
            }
        }
        .sheet(isPresented: $showSourceEditor, onDismiss: onSourceEditorDismiss) {
            NavigationStack {
                SourceSelectionView(
                    selectedTopics: editingTopics,
                    selectedSources: $editingSources
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { showSourceEditor = false }
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Preference Section

    @ViewBuilder
    private func preferenceSectionView(title: String, items: [String], editAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("Edit", action: editAction)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }

            if items.isEmpty {
                Text("None selected")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(in: .capsule)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Editing Actions

    private func startEditingTopics() {
        editingTopics = Set(categories)
        originalTopics = Set(categories)
        showTopicEditor = true
    }

    private func startEditingSources() {
        editingSources = Set(sources)
        showSourceEditor = true
    }

    private func onTopicEditorDismiss() {
        if editingTopics != originalTopics {
            // Topics changed: clear sources and force source re-selection
            editingSources = []
            topicsDidChange = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showSourceEditor = true
            }
        }
    }

    private func onSourceEditorDismiss() {
        if topicsDidChange && editingSources.isEmpty {
            // User changed topics but didn't pick sources — revert topics
            editingTopics = originalTopics
        }
        savePreferences()
        topicsDidChange = false
    }

    private func savePreferences() {
        categories = Array(editingTopics)
        sources = Array(editingSources)

        // Persist to SwiftData — update existing record
        let email = loggedInEmail
        let allPrefs = (try? modelContext.fetch(FetchDescriptor<UserPreferences>())) ?? []
        if let existing = allPrefs.first(where: { $0.userEmail == email }) {
            existing.selectedTopics = Array(editingTopics)
            existing.selectedSources = Array(editingSources)
        } else {
            let prefs = UserPreferences(
                userEmail: email,
                selectedTopics: Array(editingTopics),
                selectedSources: Array(editingSources),
                hasCompletedOnboarding: true
            )
            modelContext.insert(prefs)
        }
        try? modelContext.save()
    }
}
