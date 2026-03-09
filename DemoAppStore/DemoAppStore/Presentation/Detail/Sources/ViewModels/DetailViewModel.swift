import Core
import Domain
import Foundation

@MainActor
public final class DetailViewModel: ObservableObject {
    @Published public private(set) var app: AppInfo?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let fetchUseCase: AppStoreFetchUseCase

    public init(fetchUseCase: AppStoreFetchUseCase = Container.shared.resolve()) {
        self.fetchUseCase = fetchUseCase
    }

    public func fetchOneApp(genreId: Int = 6015) async {
        guard !isLoading else { return }
        if app != nil { return }

        isLoading = true
        errorMessage = nil

        do {
            let apps = try await fetchUseCase.execute(term: "app", genreId: genreId, limit: 1, offset: 0)
            app = apps.first
            if app == nil {
                errorMessage = "데이터가 없습니다."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
