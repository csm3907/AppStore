import Core
import Domain
import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var apps: [AppInfo] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let fetchUseCase: AppStoreFetchUseCase

    public init(fetchUseCase: AppStoreFetchUseCase = Container.shared.resolve()) {
        self.fetchUseCase = fetchUseCase
    }

    public func fetchApps(genreId: Int, limit: Int = 20, offset: Int = 0) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await fetchUseCase.execute(
                genreId: genreId,
                limit: limit,
                offset: offset
            )
            apps = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
