import Foundation

public struct AppStoreFetchUseCase {
    private let repository: AppStoreListRepository

    public init(repository: AppStoreListRepository) {
        self.repository = repository
    }

    public func execute(
        genreId: Int,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [AppInfo] {
        return try await repository.fetchApps(
            genreId: genreId,
            limit: limit,
            offset: offset
        )
    }
}
