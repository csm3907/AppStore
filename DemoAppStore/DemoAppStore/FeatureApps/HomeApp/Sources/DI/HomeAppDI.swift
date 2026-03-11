import Core
import Data
import Domain
import Foundation

enum HomeAppDI {
    static func register() {
        let container = Container.shared

        container.register(NetworkClientProtocol.self) {
            NetworkClient()
        }

        container.register(AppStoreFetchUseCase.self) {
            let repository = AppStoreListRepositoryImpl(client: container.resolve())
            return AppStoreFetchUseCase(repository: repository)
        }
    }
}
