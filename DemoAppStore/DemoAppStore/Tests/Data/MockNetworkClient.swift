import Foundation
import Core
@testable import Data

public final class MockNetworkClient: NetworkClientProtocol {
    public var getResult: Result<Data, Error> = .success(Data())
    public var getCallCount = 0
    public var lastGetURL: URL?
    
    public var postResult: Result<Data, Error> = .success(Data())
    public var postCallCount = 0
    public var lastPostURL: URL?
    public var lastPostBody: Data?

    public init() {}

    public func get(
        _ url: URL,
        headers: [String: String] = [:]
    ) async throws -> Data {
        getCallCount += 1
        lastGetURL = url
        return try getResult.get()
    }

    public func get<Response: Decodable>(
        _ url: URL,
        headers: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Response {
        let data = try await get(url, headers: headers)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(data, error)
        }
    }

    public func post(
        _ url: URL,
        body: Data,
        headers: [String: String] = [:]
    ) async throws -> Data {
        postCallCount += 1
        lastPostURL = url
        lastPostBody = body
        return try postResult.get()
    }

    public func post<Body: Encodable>(
        _ url: URL,
        body: Body,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> Data {
        let jsonData = try encoder.encode(body)
        return try await post(url, body: jsonData, headers: headers)
    }

    public func post<Body: Encodable, Response: Decodable>(
        _ url: URL,
        body: Body,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Response {
        let data = try await post(url, body: body, headers: headers, encoder: encoder)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(data, error)
        }
    }
}

// MARK: - 테스트용 DI 설정
@discardableResult
func registerDataMockDependencies(container: Container) -> MockNetworkClient {
    let mockClient = MockNetworkClient()
    container.register(NetworkClientProtocol.self) { mockClient }
    container.register(AppStoreListRepositoryImpl.self) {
        AppStoreListRepositoryImpl(client: container.resolve(NetworkClientProtocol.self))
    }
    return mockClient
}
