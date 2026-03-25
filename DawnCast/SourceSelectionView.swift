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

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose your sources")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Select where you'd like to get your news")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 24)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding()
                    } else {
                        // Source chips in a flowing layout
                        FlowLayout(spacing: 12) {
                            ForEach(sources) { source in
                                let sourceId = source.id ?? ""
                                SourceChip(
                                    title: source.name ?? sourceId,
                                    isSelected: selectedSources.contains(sourceId)
                                ) {
                                    if selectedSources.contains(sourceId) {
                                        selectedSources.remove(sourceId)
                                    } else {
                                        selectedSources.insert(sourceId)
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
            do {
                sources = try await NewsService.shared.fetchSources(categories: Array(selectedTopics))
                isLoading = false
            } catch {
                errorMessage = "Failed to load sources. Please try again."
                isLoading = false
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
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .buttonStyle(isSelected ? .glassProminent : .glass)
        .tint(isSelected ? .orange : nil)
    }
}
