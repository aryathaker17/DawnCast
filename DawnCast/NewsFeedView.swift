//
//  NewsFeedView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI

struct NewsFeedView: View {
    @Binding var isAuthenticated: Bool
    let categories: [String]
    let sources: [String]

    @State private var articles: [NewsArticle] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await loadNews() }
                    }
                    .buttonStyle(.glass)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(articles) { article in
                            ArticleCard(article: article) {
                                if let urlString = article.link,
                                   let url = URL(string: urlString) {
                                    openURL(url)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await loadNews()
                }
            }
        }
        .navigationTitle("DawnCast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Log Out") {
                    withAnimation {
                        isAuthenticated = false
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadNews()
        }
    }

    private func loadNews() async {
        isLoading = articles.isEmpty
        errorMessage = nil
        print("[NewsFeedView] Loading news with categories: \(categories), sources: \(sources)")
        do {
            articles = try await NewsService.fetchNews(categories: categories, domains: sources)
            if articles.isEmpty {
                errorMessage = "No articles found. Try adjusting your topics."
            }
        } catch {
            print("[NewsFeedView] Error loading news: \(error)")
            errorMessage = "Failed to load news. Please try again."
        }
        isLoading = false
    }
}

// MARK: - Article Card

struct ArticleCard: View {
    let article: NewsArticle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Image
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(.rect(cornerRadius: 12))
                        case .failure:
                            EmptyView()
                        default:
                            Rectangle()
                                .fill(.white.opacity(0.05))
                                .frame(height: 180)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                }

                // Title
                if let title = article.title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                // Source and date row
                HStack {
                    if let source = article.sourceName {
                        Text(source)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    if let date = article.pubDate {
                        Text(date)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                // Description
                if let description = article.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}
