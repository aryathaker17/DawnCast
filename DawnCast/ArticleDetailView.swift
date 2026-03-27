//
//  ArticleDetailView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let article: NewsArticle
    @State private var page = WebPage()

    private var articleURL: URL? {
        if let link = article.link {
            return URL(string: link)
        }
        return nil
    }

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            if articleURL != nil {
                WebView(page)
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .top) {
                        if page.isLoading {
                            ProgressView(value: page.estimatedProgress)
                                .tint(.orange)
                        }
                    }
            } else {
                // Fallback if no URL available
                VStack(spacing: 16) {
                    Image(systemName: "globe.badge.chevron.backward")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text("Article not available")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let description = article.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
            }
        }
        .navigationTitle(article.sourceName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if let url = articleURL {
                page.load(url)
            }
        }
    }
}
