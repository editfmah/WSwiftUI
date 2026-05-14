import Foundation

public enum SitemapChangeFrequency: String, Codable, Sendable {
    case always
    case hourly
    case daily
    case weekly
    case monthly
    case yearly
    case never
}

public struct SitemapEntry: Sendable {
    public let url: String
    public let lastModified: Date?
    public let changeFrequency: SitemapChangeFrequency?
    public let priority: Double?
    public let includeInTrawl: Bool
    
    public init(
        url: String,
        lastModified: Date? = nil,
        changeFrequency: SitemapChangeFrequency? = nil,
        priority: Double? = nil,
        includeInTrawl: Bool = true
    ) {
        self.url = url
        self.lastModified = lastModified
        self.changeFrequency = changeFrequency
        self.priority = priority
        self.includeInTrawl = includeInTrawl
    }
}

public protocol SitemapIndexable {
    var includeInSitemap: Bool { get }
    func sitemapEntries(baseURL: String) -> [SitemapEntry]
}

public extension SitemapIndexable {
    var includeInSitemap: Bool { true }
}

public extension SitemapIndexable where Self: WebEndpoint {
    func sitemapEntries(baseURL: String) -> [SitemapEntry] {
        return [SitemapEntry(url: "\(baseURL)\(self.path)")]
    }
}
