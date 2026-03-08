import Foundation
import Testing
@testable import Domain

struct DomainTests {
    @Test
    func placeholder() async throws {
        _ = AppInfo(
            id: 1,
            name: "Test",
            seller: "Seller",
            iconUrl: nil,
            genre: "Genre",
            rating: nil,
            ratingCount: nil,
            version: "1.0",
            releaseDate: Date(),
            description: "Description",
            screenshotUrls: []
        )
    }
}
