import Foundation

public protocol FixmeRepository {
    func fetch() async throws -> [FixmeEntity]
}
