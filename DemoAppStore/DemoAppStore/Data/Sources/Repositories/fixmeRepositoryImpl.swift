import Foundation
import Domain

public struct FixmeRepositoryImpl: FixmeRepository {
    private let dataSource: FixmeDataSource

    public init(dataSource: FixmeDataSource) {
        self.dataSource = dataSource
    }

    public func fetch() async throws -> [FixmeEntity] {
        let dtos = try await dataSource.load()
        return dtos.map { FixmeEntity(id: $0.id) }
    }
}
