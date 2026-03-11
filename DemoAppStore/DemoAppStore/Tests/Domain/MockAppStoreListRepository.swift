import Foundation
import Core
@testable import Domain

final class MockAppStoreListRepository: AppStoreListRepository {
    var fetchAppsResult: Result<[AppInfoEntity], Error> = .success([])
    var fetchAppsCallCount = 0
    var lastFetchParameters: (term: String, genreId: Int, limit: Int, offset: Int)?
    
    func fetchApps(
        term: String,
        genreId: Int,
        limit: Int,
        offset: Int
    ) async throws -> [AppInfo] {
        fetchAppsCallCount += 1
        lastFetchParameters = (term, genreId, limit, offset)
        return try fetchAppsResult.get()
    }
}

// MARK: - 테스트용 DI 설정
@discardableResult
func registerMockDependencies(container: Container) -> MockAppStoreListRepository {
    let mockRepository = MockAppStoreListRepository()
    container.register(AppStoreListRepository.self) { mockRepository }
    container.register(AppStoreFetchUseCase.self) {
        AppStoreFetchUseCase(repository: container.resolve())
    }
    return mockRepository
}
