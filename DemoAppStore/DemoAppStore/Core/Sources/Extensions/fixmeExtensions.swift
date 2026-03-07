import Foundation

public extension String {
    var fixmeTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
