import SwiftUI
import UIKit

public struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let failure: () -> Failure
    @StateObject private var loader: ImageLoader

    public init(
        url: URL?,
        cache: ImageCache = MemoryImageCache.shared,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
        _loader = StateObject(wrappedValue: ImageLoader(cache: cache))
    }

    public var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else if loader.phase == .failure {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}

@MainActor
private final class ImageLoader: ObservableObject {
    enum Phase {
        case idle
        case loading
        case success
        case failure
    }

    @Published var image: UIImage?
    @Published var phase: Phase = .idle

    private let cache: ImageCache

    init(cache: ImageCache) {
        self.cache = cache
    }

    func load(from url: URL?) async {
        image = nil
        phase = .loading
        guard let url else {
            phase = .failure
            return
        }

        if let cachedImage = cache.image(for: url) {
            image = cachedImage
            phase = .success
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let fetchedImage = UIImage(data: data) {
                cache.setImage(fetchedImage, for: url)
                image = fetchedImage
                phase = .success
            } else {
                phase = .failure
            }
        } catch {
            phase = .failure
        }
    }
}
