import Foundation
import Domain

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

    public let trackCensoredName: String?
    public let artistName: String?
    public let artistId: Int?
    public let artistViewUrl: String?
    public let sellerUrl: String?
    public let sellerId: Int?

    public let bundleId: String?
    public let kind: String?
    public let releaseDate: String?
    public let releaseNotes: String?
    public let minimumOsVersion: String?
    public let fileSizeBytes: String?
    public let contentAdvisoryRating: String?

    public let formattedPrice: String?
    public let price: Double?
    public let currency: String?
    public let isVppDeviceBasedLicensingEnabled: Bool?

    public let artworkUrl60: String?
    public let artworkUrl512: String?
    public let ipadScreenshotUrls: [String]?
    public let appletvScreenshotUrls: [String]?

    public let supportedDevices: [String]?
    public let features: [String]?
    public let advisories: [String]?
    public let languageCodesISO2A: [String]?

    public let averageUserRatingForCurrentVersion: Double?
    public let userRatingCountForCurrentVersion: Int?

    public let genres: [String]?
    public let genreIds: [String]?
    public let primaryGenreId: Int?

    public let trackViewUrl: String?
    public let trackContentRating: String?
    public let isGameCenterEnabled: Bool?

    public func toDomain() throws -> AppInfoEntity {
        let iconUrl = URL(string: artworkUrl100)
        let screenshots = screenshotUrls.compactMap { URL(string: $0) }

        guard let releaseDate = Self.parseDate(currentVersionReleaseDate) else {
            throw AppStoreRepositoryError.invalidReleaseDate(currentVersionReleaseDate)
        }

        return AppInfoEntity(
            id: trackId,
            name: trackName,
            seller: sellerName,
            iconUrl: iconUrl,
            genre: primaryGenreName,
            rating: averageUserRating,
            ratingCount: userRatingCount,
            version: version,
            releaseDate: releaseDate,
            description: description,
            screenshotUrls: screenshots
        )
    }

    private static func parseDate(_ value: String) -> Date? {
        for formatter in dateFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static let dateFormatters: [ISO8601DateFormatter] = {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]

        return [withFractional, withoutFractional]
    }()
}
