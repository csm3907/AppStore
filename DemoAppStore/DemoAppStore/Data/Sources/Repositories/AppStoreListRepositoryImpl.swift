import Foundation
import Core
import Domain

public enum AppStoreRepositoryError: Error {
    case invalidURL
    case invalidReleaseDate(String)
}

public struct AppStoreListRepositoryImpl: AppStoreListRepository {
    private let client: NetworkClientProtocol
    private let baseURL: URL
    private let country: String
    private let entity: String
    public init(
        client: NetworkClientProtocol,
        baseURL: URL = URL(string: "https://itunes.apple.com/search")!,
        country: String = "KR",
        entity: String = "software"
    ) {
        self.client = client
        self.baseURL = baseURL
        self.country = country
        self.entity = entity
    }

    public func fetchApps(
        term: String,
        genreId: Int,
        limit: Int,
        offset: Int
    ) async throws -> [AppInfo] {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw AppStoreRepositoryError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "entity", value: entity),
            URLQueryItem(name: "genreId", value: String(genreId)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw AppStoreRepositoryError.invalidURL
        }

        print("[AppStoreListRepository] Request: \(url.absoluteString)")

        let response: AppStoreSearchResponse = try await client.get(
            url,
            headers: [:],
            decoder: JSONDecoder()
        )
        print("[AppStoreListRepository] Response: resultCount=\(String(describing: response.results.map({ $0.trackName })))")

        return try response.results.map { dto in
            try map(dto: dto)
        }
    }

    private func map(dto: AppStoreAppDTO) throws -> AppInfo {
        let iconUrl = URL(string: dto.artworkUrl100)
        let screenshots = dto.screenshotUrls.compactMap { URL(string: $0) }

        guard let releaseDate = Self.parseDate(dto.currentVersionReleaseDate) else {
            throw AppStoreRepositoryError.invalidReleaseDate(dto.currentVersionReleaseDate)
        }

        return AppInfo(
            id: dto.trackId,
            name: dto.trackName,
            seller: dto.sellerName,
            iconUrl: iconUrl,
            genre: dto.primaryGenreName,
            rating: dto.averageUserRating,
            ratingCount: dto.userRatingCount,
            version: dto.version,
            releaseDate: releaseDate,
            description: dto.description,
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
