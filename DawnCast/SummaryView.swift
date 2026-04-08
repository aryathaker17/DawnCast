//
//  SummaryView.swift
//  DawnCast
//

import SwiftUI

struct SummaryView: View {
    let categories: [String]
    let sources: [String]
    var country: String = ""
    @Binding var selectedTab: AppTab

    @State private var summaries: [CategorySummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            if isLoading && !hasLoadedOnce {
                loadingView
            } else if let errorMessage, summaries.isEmpty {
                errorView(message: errorMessage)
            } else if summaries.isEmpty && hasLoadedOnce {
                emptyStateView
            } else {
                summaryListView
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if !hasLoadedOnce {
                await loadSummaries()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text("Generating your summaries…")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadSummaries() }
            }
            .buttonStyle(.glass)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("No Summaries Available")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("No articles found for your selected categories. Try adjusting your topics in Profile.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Summary List

    private var summaryListView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Refreshing…")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                ForEach(summaries) { summary in
                    CategorySummaryCard(
                        summary: summary,
                        onArticleTap: {
                            selectedTab = .feed
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            await loadSummaries()
        }
    }

    // MARK: - Data Loading

    private func loadSummaries() async {
        isLoading = true
        errorMessage = nil

        do {
            let articles = try await NewsService.fetchNews(categories: categories, sourceIds: sources, country: country)

            guard !articles.isEmpty else {
                errorMessage = "No articles found for your topics."
                isLoading = false
                hasLoadedOnce = true
                return
            }

            let generated = try await SummaryService.generateAllSummaries(
                articles: articles,
                categories: categories
            )

            summaries = generated

            if summaries.isEmpty {
                errorMessage = "Could not generate summaries. Try pulling to refresh."
            }
        } catch {
            print("[SummaryView] Error: \(error)")
            if summaries.isEmpty {
                errorMessage = "Failed to generate summaries: \(error.localizedDescription)"
            }
        }

        isLoading = false
        hasLoadedOnce = true
    }
}

// MARK: - Category Summary Card

struct CategorySummaryCard: View {
    let summary: CategorySummary
    let onArticleTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category header
            HStack {
                Image(systemName: iconForCategory(summary.category))
                    .foregroundStyle(.orange)
                Text(summary.category.capitalized)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            // Summary paragraph
            Text(summary.summaryText)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(6)

            Divider()
                .overlay(.white.opacity(0.15))

            // Referenced articles
            VStack(alignment: .leading, spacing: 6) {
                Text("Stories referenced:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))

                ForEach(summary.referencedArticles) { article in
                    Button {
                        onArticleTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(article.title ?? "Untitled")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "politics": return "building.columns"
        case "business": return "chart.line.uptrend.xyaxis"
        case "technology": return "cpu"
        case "science": return "atom"
        case "sports": return "sportscourt"
        case "health": return "heart"
        case "entertainment": return "film"
        case "environment": return "leaf"
        case "education": return "graduationcap"
        case "food": return "fork.knife"
        case "world": return "globe"
        case "crime": return "shield"
        case "lifestyle": return "sparkles"
        case "tourism": return "airplane"
        case "domestic": return "house"
        case "top": return "star"
        default: return "newspaper"
        }
    }
}
