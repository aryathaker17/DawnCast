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

    var id: String { articleId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case articleId = "article_id"
        case title, link
        case sourceId = "source_id"
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case pubDate = "pubDate"
        case category, description
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

// MARK: - News Service

enum NewsService {
    private static let apiKey = "pub_cc9ab0c0baa842ae8ffeab2ef2609a52"
    private static let baseURL = "https://newsdata.io/api/1"

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

    /// Fetches news sources filtered by selected categories.
    static func fetchSources(categories: [String]) async throws -> [NewsSource] {
        var components = URLComponents(string: "\(baseURL)/sources")!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]

        if !categories.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: categories.joined(separator: ",")))
        }
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        queryItems.append(URLQueryItem(name: "prioritydomain", value: "medium"))

        components.queryItems = queryItems

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(SourcesResponse.self, from: data)
        return response.results ?? []
    }

    /// Fetches latest news articles based on categories and source domains.
    static func fetchNews(categories: [String], domains: [String]) async throws -> [NewsArticle] {
        var components = URLComponents(string: "\(baseURL)/latest")!
        var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]

        if !categories.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: categories.joined(separator: ",")))
        }
        if !domains.isEmpty {
            queryItems.append(URLQueryItem(name: "domain", value: domains.joined(separator: ",")))
        }
        queryItems.append(URLQueryItem(name: "language", value: "en"))
        queryItems.append(URLQueryItem(name: "prioritydomain", value: "medium"))

        components.queryItems = queryItems

        let url = components.url!
        print("[NewsService] Fetching news from: \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        let rawJSON = String(data: data, encoding: .utf8) ?? "nil"
        print("[NewsService] News response: \(rawJSON.prefix(500))")
        let response = try JSONDecoder().decode(NewsResponse.self, from: data)
        print("[NewsService] Parsed \(response.results?.count ?? 0) articles")
        return response.results ?? []
    }
}
