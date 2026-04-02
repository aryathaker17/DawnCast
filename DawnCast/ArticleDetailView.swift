//
//  ArticleDetailView.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.openURL) private var openURL

    @State private var fetchedContent: String?
    @State private var isFetchingContent = false

    /// Show fetched full content first, then API content, then description.
    private var articleBody: String? {
        if let fetched = fetchedContent, !fetched.isEmpty {
            return fetched
        }
        if let content = article.content, !content.isEmpty {
            return content
        }
        return article.description
    }

    /// Format the raw pubDate string into a readable date.
    private var formattedDate: String? {
        guard let raw = article.pubDate else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: raw) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return raw
    }

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero image
                    if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 260)
                                    .clipped()
                            case .failure:
                                EmptyView()
                            default:
                                Rectangle()
                                    .fill(.white.opacity(0.05))
                                    .frame(height: 260)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        // Categories
                        if let categories = article.category, !categories.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category.capitalized)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .glassEffect(in: .capsule)
                                }
                            }
                        }

                        // Title
                        if let title = article.title {
                            Text(title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }

                        // Source and date
                        HStack(spacing: 8) {
                            if let source = article.sourceName {
                                Text(source)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                            if article.sourceName != nil && formattedDate != nil {
                                Circle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 4, height: 4)
                            }
                            if let date = formattedDate {
                                Text(date)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        Divider()
                            .overlay(.white.opacity(0.15))

                        // Article content
                        if let body = articleBody {
                            Text(body)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(8)
                        } else if isFetchingContent {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                                Text("Loading article…")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                        }

                        // Read Full Article button
                        if let urlString = article.link, let url = URL(string: urlString) {
                            Button {
                                openURL(url)
                            } label: {
                                HStack {
                                    Text("Read Full Article")
                                    Spacer()
                                    Image(systemName: "safari")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.orange)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await fetchFullContent()
        }
    }

    /// Attempts to fetch and extract readable text from the article's source URL.
    private func fetchFullContent() async {
        guard fetchedContent == nil,
              let urlString = article.link,
              let url = URL(string: urlString) else { return }

        isFetchingContent = true
        defer { isFetchingContent = false }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8)
                       ?? String(data: data, encoding: .ascii) else { return }

            // Run extraction off the main actor to avoid freezing the UI
            let extracted = await Task.detached(priority: .userInitiated) {
                await ArticleTextExtractor.extract(from: html)
            }.value

            if !extracted.isEmpty {
                fetchedContent = extracted
            }
        } catch {
            print("[ArticleDetailView] Failed to fetch article content: \(error)")
        }
    }
}

// MARK: - Article Text Extractor

/// Extracts readable paragraph text from HTML, filtering out scripts, styles, and non-content blocks.
private enum ArticleTextExtractor {

    static func extract(from html: String) -> String {
        // 1. Remove <script>, <style>, <noscript>, and HTML comments entirely
        var cleaned = html
        let removePatterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<noscript[^>]*>[\\s\\S]*?</noscript>",
            "<!--[\\s\\S]*?-->"
        ]
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }

        // 2. Extract text from <p> tags
        var paragraphs: [String] = []
        let pRegex = try? NSRegularExpression(pattern: "<p[^>]*>(.*?)</p>", options: [.caseInsensitive, .dotMatchesLineSeparators])
        if let pRegex {
            let matches = pRegex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
            for match in matches {
                guard let contentRange = Range(match.range(at: 1), in: cleaned) else { continue }
                let inner = String(cleaned[contentRange])
                let text = stripTags(inner)
                if text.count > 40 && !looksLikeCode(text) {
                    paragraphs.append(text)
                }
            }
        }

        return paragraphs.joined(separator: "\n\n")
    }

    /// Fast regex-based HTML tag removal.
    private static func stripTags(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else { return string }
        var result = regex.stringByReplacingMatches(in: string, range: NSRange(string.startIndex..., in: string), withTemplate: "")
        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&mdash;", "—"), ("&ndash;", "–"),
            ("&rsquo;", "\u{2019}"), ("&lsquo;", "\u{2018}"),
            ("&rdquo;", "\u{201C}"), ("&ldquo;", "\u{201D}"),
            ("&hellip;", "…")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // Decode numeric entities like &#8217;
        if let numericRegex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let nsResult = NSMutableString(string: result)
            let numMatches = numericRegex.matches(in: result, range: NSRange(location: 0, length: nsResult.length))
            for match in numMatches.reversed() {
                if let numRange = Range(match.range(at: 1), in: result),
                   let codePoint = UInt32(result[numRange]),
                   let scalar = Unicode.Scalar(codePoint) {
                    nsResult.replaceCharacters(in: match.range, with: String(Character(scalar)))
                }
            }
            result = nsResult as String
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Heuristic to filter out text that looks like CSS, JS, or code rather than article content.
    private static func looksLikeCode(_ text: String) -> Bool {
        let codeIndicators = ["{", "}", "function(", "function ", "var ", "margin:", "padding:",
                              "display:", "font-size:", "color:", "background:", "border:",
                              "@media", "window.", "document.", "console.", ".css", ".js",
                              "getElementById", "querySelector", "addEventListener"]
        let lowerText = text.lowercased()
        var hits = 0
        for indicator in codeIndicators {
            if lowerText.contains(indicator) { hits += 1 }
            if hits >= 2 { return true }
        }
        return false
    }
}
