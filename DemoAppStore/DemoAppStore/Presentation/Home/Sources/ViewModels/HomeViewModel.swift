import Core
import Domain
import Foundation
import SwiftUI

@MainActor
public final class HomeViewModel: ObservableObject {
    private let memoCharacterLimit = 100
    @Published public var apps: [AppInfo] = []
    @Published public var isLoading = false
    @Published public private(set) var isLoadingMore = false
    @Published public private(set) var errorMessage: String?

    @AppStorage("memo.store.data") private var memoStoreData: Data = Data()

    private let fetchUseCase: AppStoreFetchUseCase
    private var debounceTask: Task<Void, Never>?
    private var offsetsByGenre: [Int: Int] = [:]
    private var endReachedGenres: Set<Int> = []
    private var currentGenreId: Int?

    public init(fetchUseCase: AppStoreFetchUseCase = Container.shared.resolve()) {
        self.fetchUseCase = fetchUseCase
    }

    public func requestFetch(term: String, genreId: Int, limit: Int = 20, offset: Int = 0) {
        isLoading = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
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
                offsetsByGenre[genreId] = offset + result.count
                if reachedEnd {
                    endReachedGenres.insert(genreId)
                }
            } else {
                apps = result
                offsetsByGenre[genreId] = result.count
                if result.count < limit {
                    endReachedGenres.insert(genreId)
                }
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

    public func saveMemo(_ text: String, for appId: Int) {
        let limitedText = String(text.prefix(memoCharacterLimit))
        var store = loadMemoStore()
        store[appId] = limitedText
        memoStoreData = encodeMemoStore(store)
        objectWillChange.send()
    }

    public func memo(for appId: Int) -> String? {
        loadMemoStore()[appId]
    }

    public func clearMemos() {
        memoStoreData = Data()
        objectWillChange.send()
    }

    private func loadMemoStore() -> [Int: String] {
        guard !memoStoreData.isEmpty else {
            return [:]
        }
        return (try? JSONDecoder().decode([Int: String].self, from: memoStoreData)) ?? [:]
    }

    private func encodeMemoStore(_ store: [Int: String]) -> Data {
        (try? JSONEncoder().encode(store)) ?? Data()
    }
}
