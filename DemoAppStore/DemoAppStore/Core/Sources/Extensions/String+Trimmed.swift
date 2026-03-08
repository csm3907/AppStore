import Foundation

public extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
