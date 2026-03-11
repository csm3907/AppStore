import Foundation
import Testing
import Core
@testable import Data
@testable import Domain

struct AppStoreListRepositoryImplTests {
    
    // MARK: - 성공 케이스
    @Test
    func fetchApps_성공시_앱목록반환() async throws {
        // Given - DI Container로 Mock 주입
        let container = Container()
        let mockClient = registerDataMockDependencies(container: container)
        
        let mockResponse = createMockResponse(apps: [
            createMockAppDTO(id: 1, name: "카카오톡"),
            createMockAppDTO(id: 2, name: "카카오맵")
        ])
        mockClient.getResult = .success(try JSONEncoder().encode(mockResponse))
        
        let repository: AppStoreListRepositoryImpl = container.resolve()
        
        // When
        let result = try await repository.fetchApps(term: "카카오", genreId: 6015, limit: 20, offset: 0)
        
        // Then
        #expect(result.count == 2)
        #expect(result[0].name == "카카오톡")
        #expect(result[1].name == "카카오맵")
        #expect(mockClient.getCallCount == 1)
    }
    
    // MARK: - URL 파라미터 검증
    @Test
    func fetchApps_URL파라미터가_올바르게_생성됨() async throws {
        // Given
        let container = Container()
        let mockClient = registerDataMockDependencies(container: container)
        
        let mockResponse = createMockResponse(apps: [])
        mockClient.getResult = .success(try JSONEncoder().encode(mockResponse))
        
        let repository: AppStoreListRepositoryImpl = container.resolve()
        
        // When
        _ = try await repository.fetchApps(term: "게임", genreId: 6014, limit: 10, offset: 5)
        
        // Then
        let url = mockClient.lastGetURL
        #expect(url != nil)
        
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        #expect(queryItems.contains { $0.name == "term" && $0.value == "게임" })
        #expect(queryItems.contains { $0.name == "genreId" && $0.value == "6014" })
        #expect(queryItems.contains { $0.name == "limit" && $0.value == "10" })
        #expect(queryItems.contains { $0.name == "offset" && $0.value == "5" })
        #expect(queryItems.contains { $0.name == "country" && $0.value == "KR" })
        #expect(queryItems.contains { $0.name == "entity" && $0.value == "software" })
    }
    
    // MARK: - DTO -> Entity 매핑 검증
    @Test
    func fetchApps_DTO가_Entity로_올바르게_매핑됨() async throws {
        // Given
        let container = Container()
        let mockClient = registerDataMockDependencies(container: container)
        
        let mockResponse = createMockResponse(apps: [
            createMockAppDTO(
                id: 123,
                name: "테스트앱",
                seller: "테스트회사",
                genre: "게임",
                rating: 4.5,
                ratingCount: 1000,
                version: "2.0.0"
            )
        ])
        mockClient.getResult = .success(try JSONEncoder().encode(mockResponse))
        
        let repository: AppStoreListRepositoryImpl = container.resolve()
        
        // When
        let result = try await repository.fetchApps(term: "test", genreId: 6015, limit: 20, offset: 0)
        
        // Then
        #expect(result.count == 1)
        let app = result[0]
        #expect(app.id == 123)
        #expect(app.name == "테스트앱")
        #expect(app.seller == "테스트회사")
        #expect(app.genre == "게임")
        #expect(app.rating == 4.5)
        #expect(app.ratingCount == 1000)
        #expect(app.version == "2.0.0")
    }
    
    // MARK: - 네트워크 에러 케이스
    @Test
    func fetchApps_네트워크에러시_에러전파() async throws {
        // Given
        let container = Container()
        let mockClient = registerDataMockDependencies(container: container)
        
        let expectedError = NetworkError.httpStatus(500)
        mockClient.getResult = .failure(expectedError)
        
        let repository: AppStoreListRepositoryImpl = container.resolve()
        
        // When & Then
        await #expect(throws: Error.self) {
            try await repository.fetchApps(term: "test", genreId: 6015, limit: 20, offset: 0)
        }
    }
    
    // MARK: - 빈 결과 케이스
    @Test
    func fetchApps_빈결과시_빈배열반환() async throws {
        // Given
        let container = Container()
        let mockClient = registerDataMockDependencies(container: container)
        
        let mockResponse = createMockResponse(apps: [])
        mockClient.getResult = .success(try JSONEncoder().encode(mockResponse))
        
        let repository: AppStoreListRepositoryImpl = container.resolve()
        
        // When
        let result = try await repository.fetchApps(term: "없는앱", genreId: 6015, limit: 20, offset: 0)
        
        // Then
        #expect(result.isEmpty)
    }
}

// MARK: - Helpers
private func createMockResponse(apps: [AppStoreAppDTO]) -> AppStoreSearchResponse {
    AppStoreSearchResponse(resultCount: apps.count, results: apps)
}

private func createMockAppDTO(
    id: Int,
    name: String,
    seller: String = "Test Seller",
    genre: String = "게임",
    rating: Double? = 4.0,
    ratingCount: Int? = 100,
    version: String = "1.0.0"
) -> AppStoreAppDTO {
    AppStoreAppDTO(
        trackId: id,
        trackName: name,
        sellerName: seller,
        artworkUrl100: "https://example.com/icon.png",
        primaryGenreName: genre,
        averageUserRating: rating,
        userRatingCount: ratingCount,
        version: version,
        currentVersionReleaseDate: "2024-01-01T00:00:00Z",
        description: "Test Description",
        screenshotUrls: ["https://example.com/screenshot1.png"]
    )
}
