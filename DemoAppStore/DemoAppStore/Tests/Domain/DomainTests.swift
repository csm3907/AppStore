import Foundation
import Testing
import Core
@testable import Domain

struct AppStoreFetchUseCaseTests {
    
    // MARK: - 성공 케이스
    @Test
    func execute_성공시_앱목록반환() async throws {
        // Given - DI Container로 Mock 주입
        let container = Container()
        let mockRepository = registerMockDependencies(container: container)
        let expectedApps = [createMockAppInfo(id: 1, name: "App1")]
        mockRepository.fetchAppsResult = .success(expectedApps)
        
        let useCase: AppStoreFetchUseCase = container.resolve()
        
        // When
        let result = try await useCase.execute(term: "test", genreId: 6015)
        
        // Then
        #expect(result == expectedApps)
        #expect(mockRepository.fetchAppsCallCount == 1)
    }
    
    // MARK: - 파라미터 전달 검증
    @Test
    func execute_파라미터가_올바르게_전달됨() async throws {
        // Given
        let container = Container()
        let mockRepository = registerMockDependencies(container: container)
        let useCase: AppStoreFetchUseCase = container.resolve()
        
        // When
        _ = try await useCase.execute(term: "카카오", genreId: 6015, limit: 10, offset: 5)
        
        // Then
        #expect(mockRepository.lastFetchParameters?.term == "카카오")
        #expect(mockRepository.lastFetchParameters?.genreId == 6015)
        #expect(mockRepository.lastFetchParameters?.limit == 10)
        #expect(mockRepository.lastFetchParameters?.offset == 5)
    }
    
    // MARK: - 기본값 검증
    @Test
    func execute_기본값_limit20_offset0() async throws {
        // Given
        let container = Container()
        let mockRepository = registerMockDependencies(container: container)
        let useCase: AppStoreFetchUseCase = container.resolve()
        
        // When
        _ = try await useCase.execute(term: "test", genreId: 6015)
        
        // Then
        #expect(mockRepository.lastFetchParameters?.limit == 20)
        #expect(mockRepository.lastFetchParameters?.offset == 0)
    }
    
    // MARK: - 에러 케이스
    @Test
    func execute_실패시_에러전파() async throws {
        // Given
        let container = Container()
        let mockRepository = registerMockDependencies(container: container)
        let expectedError = NSError(domain: "TestError", code: -1)
        mockRepository.fetchAppsResult = .failure(expectedError)
        
        let useCase: AppStoreFetchUseCase = container.resolve()
        
        // When & Then
        await #expect(throws: Error.self) {
            try await useCase.execute(term: "test", genreId: 6015)
        }
    }
}

// MARK: - Helper
private func createMockAppInfo(id: Int, name: String) -> AppInfoEntity {
    AppInfoEntity(
        id: id,
        name: name,
        seller: "Test Seller",
        iconUrl: nil,
        genre: "게임",
        rating: 4.5,
        ratingCount: 100,
        version: "1.0.0",
        releaseDate: Date(),
        description: "Test Description",
        screenshotUrls: []
    )
}
