import Foundation
import Testing
@testable import Core

private struct StubSession: NetworkSession {
    let data: Data
    let response: URLResponse

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return (data, response)
    }
}

struct NetworkRequestBuilderTests {
    @Test
    func makeRequestMergesHeadersAndSetsProperties() {
        let configuration = NetworkConfiguration(
            defaultHeaders: ["X-Default": "default", "X-Override": "old"],
            timeout: 12
        )
        let builder = NetworkRequestBuilder()
        let url = URL(string: "https://example.com")!
        let body = Data([0x01, 0x02])

        let request = builder.makeRequest(
            url: url,
            method: "POST",
            headers: ["X-Override": "new", "X-Extra": "value"],
            body: body,
            configuration: configuration
        )

        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == body)
        #expect(request.timeoutInterval == 12)
        #expect(request.value(forHTTPHeaderField: "X-Default") == "default")
        #expect(request.value(forHTTPHeaderField: "X-Override") == "new")
        #expect(request.value(forHTTPHeaderField: "X-Extra") == "value")
    }
}

struct NetworkClientTests {
    @Test
    func getThrowsHttpStatusError() async {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = StubSession(data: Data(), response: response)
        let client = NetworkClient(session: session)

        do {
            _ = try await client.get(url)
            #expect(false)
        } catch let error as NetworkError {
            switch error {
            case .httpStatus(let code):
                #expect(code == 404)
            default:
                #expect(false)
            }
        } catch {
            #expect(false)
        }
    }

    @Test
    func getDecodingFailureWrapsError() async {
        struct Payload: Decodable {
            let value: Int
        }

        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let badData = Data("not-json".utf8)
        let session = StubSession(data: badData, response: response)
        let client = NetworkClient(session: session)

        do {
            _ = try await client.get(url) as Payload
            #expect(false)
        } catch let error as NetworkError {
            switch error {
            case .decodingError(let data, _):
                #expect(data == badData)
            default:
                #expect(false)
            }
        } catch {
            #expect(false)
        }
    }
}
