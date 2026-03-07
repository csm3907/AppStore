import Foundation

public protocol FixmeDataSource {
    func load() async throws -> [FixmeDTO]
}
