import PresentationDetail
import SwiftUI

struct DetailAppRootView: View {
    @StateObject private var viewModel = DetailViewModel()

    var body: some View {
        Group {
            if let app = viewModel.app {
                DetailView(app: app, showsFullScreenButton: true, showsCloseButton: false)
            } else if viewModel.isLoading {
                ProgressView()
            } else if let message = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("다시 시도") {
                        Task { await viewModel.fetchOneApp() }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchOneApp()
        }
    }
}
