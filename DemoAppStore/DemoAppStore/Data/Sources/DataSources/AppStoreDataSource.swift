import Foundation

public protocol AppStoreDataSource {
    func load() async throws -> AppStoreSearchResponse
}
