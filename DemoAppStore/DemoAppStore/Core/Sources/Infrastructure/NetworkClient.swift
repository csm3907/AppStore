import Foundation

public struct NetworkConfiguration {
    public let defaultHeaders: [String: String]
    public let timeout: TimeInterval

    public init(
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30
    ) {
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
    }
}

public protocol NetworkClientProtocol {
    func get(
        _ url: URL,
        headers: [String: String]
    ) async throws -> Data

    func get<Response: Decodable>(
        _ url: URL,
        headers: [String: String],
        decoder: JSONDecoder
    ) async throws -> Response

    func post(
        _ url: URL,
        body: Data,
        headers: [String: String]
    ) async throws -> Data

    func post<Body: Encodable>(
        _ url: URL,
        body: Body,
        headers: [String: String],
        encoder: JSONEncoder
    ) async throws -> Data

    func post<Body: Encodable, Response: Decodable>(
        _ url: URL,
        body: Body,
        headers: [String: String],
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) async throws -> Response
}

public struct NetworkClient: NetworkClientProtocol {
    private let configuration: NetworkConfiguration
    private let session: NetworkSession
    private let requestBuilder: NetworkRequestBuilder

    public init(
        configuration: NetworkConfiguration = NetworkConfiguration(),
        session: NetworkSession = URLSession.shared,
        requestBuilder: NetworkRequestBuilder = NetworkRequestBuilder()
    ) {
        self.configuration = configuration
        self.session = session
        self.requestBuilder = requestBuilder
    }

    public func get(
        _ url: URL,
        headers: [String: String] = [:]
    ) async throws -> Data {
        return try await request(
            url,
            method: "GET",
            headers: headers,
            body: nil
        )
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
        return try await request(
            url,
            method: "POST",
            headers: headers,
            body: body
        )
    }

    public func post<Body: Encodable>(
        _ url: URL,
        body: Body,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> Data {
        let jsonData = try encoder.encode(body)
        var mergedHeaders = headers
        if mergedHeaders["Content-Type"] == nil {
            mergedHeaders["Content-Type"] = "application/json"
        }

        return try await post(
            url,
            body: jsonData,
            headers: mergedHeaders
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

    private func request(
        _ url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> Data {
        let request = requestBuilder.makeRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            configuration: configuration
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }

        return data
    }
}

public protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}
