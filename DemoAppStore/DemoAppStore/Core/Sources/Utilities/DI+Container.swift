import Foundation

public final class Container {
    public static let shared = Container()

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private let lock = NSLock()

    public init() {}

    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        lock.lock()
        factories[key] = factory
        lock.unlock()
    }

    public func resolve<T>(_ type: T.Type = T.self) -> T {
        let key = ObjectIdentifier(type)
        lock.lock()
        let factory = factories[key]
        lock.unlock()

        guard let value = factory?() as? T else {
            fatalError("No registration for \(type)")
        }

        return value
    }

    public func resolveOptional<T>(_ type: T.Type = T.self) -> T? {
        let key = ObjectIdentifier(type)
        lock.lock()
        let factory = factories[key]
        lock.unlock()

        return factory?() as? T
    }
}
