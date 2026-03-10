import Foundation

public struct AppStoreSearchResponse: Codable {
    public let resultCount: Int
    public let results: [AppStoreAppDTO]
}

public struct AppStoreAppDTO: Codable {
    public let trackId: Int
    public let trackName: String
    public let sellerName: String
    public let artworkUrl100: String
    public let primaryGenreName: String
    public let averageUserRating: Double?
    public let userRatingCount: Int?
    public let version: String
    public let currentVersionReleaseDate: String
    public let description: String
    public let screenshotUrls: [String]
}
