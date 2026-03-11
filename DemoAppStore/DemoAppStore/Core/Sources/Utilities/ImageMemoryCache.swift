import UIKit

public protocol ImageCache {
    func image(for url: URL) -> UIImage?
    func setImage(_ image: UIImage, for url: URL)
    func removeImage(for url: URL)
    func removeAll()
}

public final class MemoryImageCache: ImageCache {
    public static let shared = MemoryImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    public init() {}

    public func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    public func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL, cost: cost(for: image))
    }

    private func cost(for image: UIImage) -> Int {
        if let cgImage = image.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }

        let scale = image.scale
        let pixels = image.size.width * scale * image.size.height * scale
        return Int(pixels * 4)
    }

    public func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}
