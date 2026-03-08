import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case httpStatus(Int)
    case decodingError(Data, Error)
}
