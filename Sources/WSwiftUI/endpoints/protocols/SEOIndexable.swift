import Foundation

public struct OpenGraphMetadata: Sendable {
    public let type: String?
    public let title: String?
    public let description: String?
    public let url: String?
    public let imageURL: String?
    public let siteName: String?
    public let locale: String?
    
    public init(
        type: String? = nil,
        title: String? = nil,
        description: String? = nil,
        url: String? = nil,
        imageURL: String? = nil,
        siteName: String? = nil,
        locale: String? = nil
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.url = url
        self.imageURL = imageURL
        self.siteName = siteName
        self.locale = locale
    }
}

public struct TwitterCardMetadata: Sendable {
    public let card: String
    public let title: String?
    public let description: String?
    public let imageURL: String?
    public let site: String?
    
    public init(
        card: String = "summary_large_image",
        title: String? = nil,
        description: String? = nil,
        imageURL: String? = nil,
        site: String? = nil
    ) {
        self.card = card
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.site = site
    }
}

public struct PageSEO: Sendable {
    public let title: String?
    public let description: String?
    public let canonicalPath: String?
    public let canonicalURL: String?
    public let robots: String?
    public let keywords: [String]
    public let openGraph: OpenGraphMetadata?
    public let twitter: TwitterCardMetadata?
    public let jsonLD: [String]
    
    public init(
        title: String? = nil,
        description: String? = nil,
        canonicalPath: String? = nil,
        canonicalURL: String? = nil,
        robots: String? = nil,
        keywords: [String] = [],
        openGraph: OpenGraphMetadata? = nil,
        twitter: TwitterCardMetadata? = nil,
        jsonLD: [String] = []
    ) {
        self.title = title
        self.description = description
        self.canonicalPath = canonicalPath
        self.canonicalURL = canonicalURL
        self.robots = robots
        self.keywords = keywords
        self.openGraph = openGraph
        self.twitter = twitter
        self.jsonLD = jsonLD
    }
}

public protocol SEOIndexable {
    func seo() -> PageSEO?
}

public extension SEOIndexable {
    func seo() -> PageSEO? {
        return nil
    }
}
