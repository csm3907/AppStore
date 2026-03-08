import Foundation

public struct AppInfo: Equatable {
    public let id: Int
    public let name: String
    public let seller: String
    public let iconUrl: URL?
    public let genre: String
    public let rating: Double?
    public let ratingCount: Int?
    public let version: String
    public let releaseDate: Date
    public let description: String
    public let screenshotUrls: [URL]

    public init(
        id: Int,
        name: String,
        seller: String,
        iconUrl: URL?,
        genre: String,
        rating: Double?,
        ratingCount: Int?,
        version: String,
        releaseDate: Date,
        description: String,
        screenshotUrls: [URL]
    ) {
        self.id = id
        self.name = name
        self.seller = seller
        self.iconUrl = iconUrl
        self.genre = genre
        self.rating = rating
        self.ratingCount = ratingCount
        self.version = version
        self.releaseDate = releaseDate
        self.description = description
        self.screenshotUrls = screenshotUrls
    }
}
