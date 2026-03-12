import Foundation
import Core
import Domain

public enum AppStoreRepositoryError: Error {
    case invalidURL
    case invalidReleaseDate(String)
}

public final class AppStoreListRepositoryImpl: AppStoreListRepository {
    private let client: NetworkClientProtocol
    private let baseURL: URL
    private let country: String
    private let entity: String
    private var cache: [Int: [AppInfoEntity]] = [:]
    
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
    
    public func clearCache() {
        cache.removeAll()
    }
    
    public func clearCache(for genreId: Int) {
        cache.removeValue(forKey: genreId)
    }

    public func fetchApps(
        term: String,
        genreId: Int,
        limit: Int,
        offset: Int
    ) async throws -> [AppInfoEntity] {
        // 캐시 히트
        if let cached = cache[genreId] {
            print("[AppStoreListRepository] Cache hit for genreId: \(genreId)")
            return cached
        }
        
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

        let apps = try response.results.map { dto in
            try dto.toDomain()
        }
        
        // 캐시 저장
        cache[genreId] = apps
        print("[AppStoreListRepository] Cached \(apps.count) apps for genreId: \(genreId)")
        
        return apps
    }

}
