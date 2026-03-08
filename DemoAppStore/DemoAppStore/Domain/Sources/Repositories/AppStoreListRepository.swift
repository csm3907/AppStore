import Foundation

public protocol AppStoreListRepository {
    func fetchApps(
        genreId: Int,
        limit: Int,
        offset: Int
    ) async throws -> [AppInfo]
}
