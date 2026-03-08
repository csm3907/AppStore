import Foundation

public struct MockNetworkClient: NetworkClientProtocol {
    public var getHandler: (URL, [String: String]) async throws -> Data
    public var postDataHandler: (URL, Data, [String: String]) async throws -> Data

    public init(
        getHandler: @escaping (URL, [String: String]) async throws -> Data,
        postDataHandler: @escaping (URL, Data, [String: String]) async throws -> Data
    ) {
        self.getHandler = getHandler
        self.postDataHandler = postDataHandler
    }

    public func get(
        _ url: URL,
        headers: [String: String] = [:]
    ) async throws -> Data {
        return try await getHandler(url, headers)
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
        return try await postDataHandler(url, body, headers)
    }

    public func post<Body: Encodable>(
        _ url: URL,
        body: Body,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> Data {
        let jsonData = try encoder.encode(body)
        return try await post(
            url,
            body: jsonData,
            headers: headers
        )
    }

    public func post<Body: Encodable, Response: Decodable>(
        _ url: URL,
        body: Body,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> Response {
        let data = try await post(
            url,
            body: body,
            headers: headers,
            encoder: encoder
        )
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(data, error)
        }
    }
}
