import Core
import Domain
import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var apps: [AppInfo] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isLoadingMore = false
    @Published public private(set) var errorMessage: String?

    private let fetchUseCase: AppStoreFetchUseCase
    private var debounceTask: Task<Void, Never>?
    private var offsetsByGenre: [Int: Int] = [:]
    private var endReachedGenres: Set<Int> = []
    private var currentGenreId: Int?

    public init(fetchUseCase: AppStoreFetchUseCase = Container.shared.resolve()) {
        self.fetchUseCase = fetchUseCase
    }

    public func requestFetch(term: String, genreId: Int, limit: Int = 20, offset: Int = 0) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            //try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.fetchAppsNow(term: term, genreId: genreId, limit: limit, offset: offset, append: false)
        }
    }

    public func loadMore(term: String, genreId: Int, limit: Int = 20) {
        Task { [weak self] in
            await self?.loadMoreNow(term: term, genreId: genreId, limit: limit)
        }
    }

    public func fetchAppsNow(
        term: String,
        genreId: Int,
        limit: Int = 20,
        offset: Int = 0,
        append: Bool
    ) async {
        if append {
            if isLoadingMore || isLoading || endReachedGenres.contains(genreId) {
                return
            }
            if let currentGenreId, currentGenreId != genreId {
                return
            }
            isLoadingMore = true
        } else {
            if isLoading {
                return
            }
            isLoading = true
            if currentGenreId != genreId {
                currentGenreId = genreId
            }
            if offset == 0 {
                offsetsByGenre[genreId] = 0
                endReachedGenres.remove(genreId)
            }
        }
        errorMessage = nil

        do {
            let result = try await fetchUseCase.execute(
                term: term,
                genreId: genreId,
                limit: limit,
                offset: offset
            )
            if append {
                let existingIds = Set(apps.map { $0.id })
                let newApps = result.filter { !existingIds.contains($0.id) }
                let reachedEnd = result.count < limit
                if !newApps.isEmpty {
                    apps.append(contentsOf: newApps)
                }
                offsetsByGenre[genreId] = offset
                if reachedEnd {
                    endReachedGenres.insert(genreId)
                }
            } else {
                apps = result
                offsetsByGenre[genreId] = offset
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        if append {
            isLoadingMore = false
        } else {
            isLoading = false
        }
    }

    private func loadMoreNow(term: String, genreId: Int, limit: Int) async {
        let currentOffset = offsetsByGenre[genreId] ?? 0
        let nextOffset = currentOffset + limit
        await fetchAppsNow(term: term, genreId: genreId, limit: limit, offset: nextOffset, append: true)
    }
}
