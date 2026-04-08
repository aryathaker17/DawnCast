//
//  SummaryService.swift
//  DawnCast
//

import Foundation

// MARK: - Claude API Models

struct ClaudeMessage: Codable, Sendable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable, Sendable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeContentBlock: Codable, Sendable {
    let type: String
    let text: String
}

struct ClaudeResponse: Codable, Sendable {
    let content: [ClaudeContentBlock]?
}

// MARK: - Summary Model

struct CategorySummary: Identifiable, Sendable {
    let id = UUID()
    let category: String
    let summaryText: String
    let referencedArticles: [NewsArticle]
}

// MARK: - Summary Service

enum SummaryService {
    private static let apiKey: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
        // xcconfig values can get duplicated when set at multiple configuration levels;
        // extract just the first non-empty line.
        return raw.components(separatedBy: .newlines).first(where: { !$0.isEmpty })?.trimmingCharacters(in: .whitespaces) ?? raw
    }()
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    /// Groups articles by their primary category, filtered to user-selected categories, top 5 each.
    static func groupArticles(_ articles: [NewsArticle], forCategories userCategories: [String]) -> [String: [NewsArticle]] {
        var grouped: [String: [NewsArticle]] = [:]
        let categorySet = Set(userCategories.map { $0.lowercased() })

        for article in articles {
            guard let categories = article.category, let primary = categories.first else { continue }
            let normalized = primary.lowercased()
            guard categorySet.contains(normalized) else { continue }
            grouped[normalized, default: []].append(article)
        }

        return grouped.mapValues { Array($0.prefix(5)) }
    }

    /// Builds the prompt for a single category.
    private static func buildPrompt(category: String, articles: [NewsArticle]) -> String {
        var prompt = """
        Summarize the following top news stories in \(category.capitalized) into a single cohesive paragraph. \
        Mention the news source for each story naturally in your writing (e.g., "According to BBC..." or "as reported by CNN"). \
        Keep it concise but informative, covering the key developments. Do not use bullet points or numbered lists. \
        Write as a single flowing paragraph.

        Articles:
        """
        for (index, article) in articles.enumerated() {
            let title = article.title ?? "Untitled"
            let source = article.sourceName ?? "Unknown Source"
            let description = article.description ?? ""
            prompt += "\n\(index + 1). \(title) (Source: \(source)) - \(description)"
        }
        return prompt
    }

    /// Calls the Claude Messages API for a single category.
    static func generateSummary(category: String, articles: [NewsArticle]) async throws -> String {
        let prompt = buildPrompt(category: category, articles: articles)

        let requestBody = ClaudeRequest(
            model: "claude-sonnet-4-20250514",
            maxTokens: 1024,
            messages: [ClaudeMessage(role: "user", content: prompt)]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, httpResponse) = try await session.data(for: request)

        guard let http = httpResponse as? HTTPURLResponse, http.statusCode == 200 else {
            let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "nil"
            print("[SummaryService] API error (HTTP \(statusCode)): \(body.prefix(500))")
            throw NSError(domain: "SummaryService", code: statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Claude API returned HTTP \(statusCode)"])
        }

        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = response.content?.first?.text else {
            throw NSError(domain: "SummaryService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response from Claude API"])
        }
        return text
    }

    /// Generates summaries for all user categories. Processes sequentially to avoid rate limits.
    static func generateAllSummaries(articles: [NewsArticle], categories: [String]) async throws -> [CategorySummary] {
        let grouped = groupArticles(articles, forCategories: categories)
        var summaries: [CategorySummary] = []

        for category in categories {
            let normalized = category.lowercased()
            guard let categoryArticles = grouped[normalized], !categoryArticles.isEmpty else { continue }

            do {
                let text = try await generateSummary(category: normalized, articles: categoryArticles)
                summaries.append(CategorySummary(
                    category: normalized,
                    summaryText: text,
                    referencedArticles: categoryArticles
                ))
            } catch {
                print("[SummaryService] Failed to generate summary for \(category): \(error)")
                // Continue with other categories
            }
        }
        return summaries
    }
}
