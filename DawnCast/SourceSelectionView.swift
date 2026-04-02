//
//  SourceSelectionView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI
import SwiftData

struct SourceSelectionView: View {
    let selectedTopics: Set<String>
    @Binding var selectedSources: Set<String>
    @State private var sources: [NewsSource] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSearch = false
    @State private var showLimitMessage = false

    private let maxSources = 4

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header with search button
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            Text("Choose your sources")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                showSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        Text("Select where you'd like to get your news")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 24)

                    if showLimitMessage {
                        Text("You can only select up to 4 sources.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(.red.opacity(0.8), in: .rect(cornerRadius: 10))
                            .padding(.horizontal, 24)
                    }

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else if let errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await loadSources() }
                            }
                            .buttonStyle(.glass)
                        }
                        .padding()
                    } else {
                        // Source chips in a flowing layout
                        FlowLayout(spacing: 12) {
                            ForEach(sources) { source in
                                let sourceId = source.id ?? ""
                                let displayName = source.name ?? sourceId
                                if !sourceId.isEmpty {
                                    SourceChip(
                                        title: displayName,
                                        isSelected: selectedSources.contains(sourceId)
                                    ) {
                                        if selectedSources.contains(sourceId) {
                                            selectedSources.remove(sourceId)
                                            showLimitMessage = false
                                        } else if selectedSources.count >= maxSources {
                                            showLimitMessage = true
                                        } else {
                                            selectedSources.insert(sourceId)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .task {
            await loadSources()
        }
        .sheet(isPresented: $showSearch) {
            SourceSearchSheet(
                sources: sources,
                selectedSources: $selectedSources,
                showLimitMessage: $showLimitMessage,
                maxSources: maxSources
            )
        }
    }

    private func loadSources() async {
        isLoading = true
        errorMessage = nil
        do {
            sources = try await NewsService.fetchSources(categories: Array(selectedTopics))
            if sources.isEmpty {
                errorMessage = "No sources found for your topics."
            }
        } catch {
            errorMessage = "Failed to load sources: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Source Search Sheet

struct SourceSearchSheet: View {
    let sources: [NewsSource]
    @Binding var selectedSources: Set<String>
    @Binding var showLimitMessage: Bool
    let maxSources: Int
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredSources: [NewsSource] {
        if searchText.isEmpty {
            return sources
        }
        let query = searchText.lowercased()
        return sources.filter { source in
            let name = (source.name ?? "").lowercased()
            let id = (source.id ?? "").lowercased()
            return name.contains(query) || id.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.04)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if showLimitMessage {
                        Text("You can only select up to 4 sources.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(.red.opacity(0.8), in: .rect(cornerRadius: 10))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    List {
                        ForEach(filteredSources) { source in
                        let sourceId = source.id ?? ""
                        let displayName = source.name ?? sourceId
                        if !sourceId.isEmpty {
                            Button {
                                if selectedSources.contains(sourceId) {
                                    selectedSources.remove(sourceId)
                                    showLimitMessage = false
                                } else if selectedSources.count >= maxSources {
                                    showLimitMessage = true
                                } else {
                                    selectedSources.insert(sourceId)
                                }
                            } label: {
                                HStack {
                                    Text(displayName)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if selectedSources.contains(sourceId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Search Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search by name...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Source Chip

struct SourceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
        } else {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glass)
        }
    }
}
