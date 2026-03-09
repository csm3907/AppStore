import Foundation

public protocol AppStoreListRepository {
    func fetchApps(
        term: String,
        genreId: Int,
        limit: Int,
        offset: Int
    ) async throws -> [AppInfo]
}
