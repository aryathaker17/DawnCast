//
//  NewsService.swift
//  DawnCast
//
//  Created by Arya Thaker on 3/25/26.
//

import Foundation

// MARK: - API Response Models

struct CategoriesResponse: Codable, Sendable {
    let results: [String]?
    let status: String?
}

struct NewsSource: Codable, Sendable, Identifiable {
    let id: String?
    let name: String?
    let url: String?
    let category: [String]?
    let language: [String]?
    let country: [String]?
}

struct SourcesResponse: Codable, Sendable {
    let results: [NewsSource]?
    let status: String?
}

struct NewsArticle: Codable, Sendable, Identifiable {
    let articleId: String?
    let title: String?
    let link: String?
    let sourceId: String?
    let sourceName: String?
    let sourceUrl: String?
    let imageUrl: String?
    let pubDate: String?
    let category: [String]?
    let description: String?
    let content: String?

    var id: String { articleId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case articleId = "article_id"
        case title, link
        case sourceId = "source_id"
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case pubDate = "pubDate"
        case category, description, content
    }
}

struct NewsResponse: Codable, Sendable {
    let results: [NewsArticle]?
    let status: String?
    let totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case results, status
        case totalResults = "totalResults"
    }
}

struct APIErrorResponse: Codable, Sendable {
    let status: String?
    let results: APIErrorDetail?
}

struct APIErrorDetail: Codable, Sendable {
    let message: String?
    let code: String?
}

// MARK: - News Service

enum NewsService {
    private static let apiKey = "pub_cc9ab0c0baa842ae8ffeab2ef2609a52"
    private static let baseURL = "https://newsdata.io/api/1"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    /// Fetches available news categories.
    static func fetchCategories() async throws -> [String] {
        // NewsData.IO has 17 known categories — use them directly
        // to avoid spending API credits on the categories endpoint.
        return [
            "business", "crime", "domestic", "education",
            "entertainment", "environment", "food", "health",
            "lifestyle", "other", "politics", "science",
            "sports", "technology", "top", "tourism", "world"
        ]
    }

    /// Fetches top news sources from the API filtered by selected categories.
    static func fetchSources(categories: [String]) async throws -> [NewsSource] {
        var components = URLComponents(string: "\(baseURL)/sources")!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]

        if !categories.isEmpty {
            let limitedCategories = Array(categories.prefix(5))
            queryItems.append(URLQueryItem(name: "category", value: limitedCategories.joined(separator: ",")))
        }
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        queryItems.append(URLQueryItem(name: "prioritydomain", value: "top"))

        components.queryItems = queryItems

        let url = components.url!
        print("[NewsService] Fetching sources from: \(url)")
        let (data, _) = try await session.data(from: url)
        let rawJSON = String(data: data, encoding: .utf8) ?? "nil"
        print("[NewsService] Sources response: \(rawJSON.prefix(500))")

        if let response = try? JSONDecoder().decode(SourcesResponse.self, from: data),
           let sources = response.results, !sources.isEmpty {
            print("[NewsService] Parsed \(sources.count) sources")
            return sources
        }

        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
           let errorDetail = errorResponse.results {
            let msg = errorDetail.message ?? "Unknown API error"
            print("[NewsService] Sources API error: \(msg)")
            throw NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        return []
    }

    /// Fetches latest news articles based on categories and selected source IDs.
    static func fetchNews(categories: [String], sourceIds: [String] = []) async throws -> [NewsArticle] {
        var components = URLComponents(string: "\(baseURL)/latest")!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]

        if !categories.isEmpty {
            let limitedCategories = Array(categories.prefix(5))
            queryItems.append(URLQueryItem(name: "category", value: limitedCategories.joined(separator: ",")))
        }
        if !sourceIds.isEmpty {
            // Free tier allows up to 5 domains per query
            let limitedSources = Array(sourceIds.prefix(5))
            queryItems.append(URLQueryItem(name: "domain", value: limitedSources.joined(separator: ",")))
        }
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        // Only use prioritydomain when no specific sources are selected
        if sourceIds.isEmpty {
            queryItems.append(URLQueryItem(name: "prioritydomain", value: "top"))
        }

        components.queryItems = queryItems

        let url = components.url!
        print("[NewsService] Fetching news from: \(url)")
        let (data, httpResponse) = try await session.data(from: url)
        let rawJSON = String(data: data, encoding: .utf8) ?? "nil"
        print("[NewsService] HTTP status: \((httpResponse as? HTTPURLResponse)?.statusCode ?? -1)")
        print("[NewsService] News response: \(rawJSON.prefix(1000))")

        // Try decoding a successful response first
        if let decoded = try? JSONDecoder().decode(NewsResponse.self, from: data),
           let articles = decoded.results, !articles.isEmpty {
            print("[NewsService] Parsed \(articles.count) articles")
            return articles
        }

        // If that failed or returned empty results, check for an API error
        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
           let errorDetail = errorResponse.results {
            let msg = errorDetail.message ?? "Unknown API error"
            print("[NewsService] API error: \(msg)")
            throw NSError(domain: "NewsService", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        // Fallback: return empty
        print("[NewsService] No articles and no error parsed from response")
        return []
    }
}
