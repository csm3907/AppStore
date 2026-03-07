import Testing
@testable import Domain

struct FixmeDomainTests {
    @Test
    func placeholder() async throws {
        _ = FixmeEntity(id: UUID())
    }
}
