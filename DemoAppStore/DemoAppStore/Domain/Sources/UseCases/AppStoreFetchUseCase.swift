import Foundation

public struct AppStoreFetchUseCase {
    private let repository: AppStoreListRepository

    public init(repository: AppStoreListRepository) {
        self.repository = repository
    }

    public func execute(
        term: String,
        genreId: Int,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [AppInfoEntity] {
        return try await repository.fetchApps(
            term: term,
            genreId: genreId,
            limit: limit,
            offset: offset
        )
    }
}
