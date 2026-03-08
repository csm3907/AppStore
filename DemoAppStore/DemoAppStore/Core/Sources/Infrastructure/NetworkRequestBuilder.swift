import Foundation

public struct NetworkRequestBuilder {
    public init() {}

    public func makeRequest(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?,
        configuration: NetworkConfiguration
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = configuration.timeout

        let mergedHeaders = configuration.defaultHeaders.merging(headers) { _, new in new }
        mergedHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
