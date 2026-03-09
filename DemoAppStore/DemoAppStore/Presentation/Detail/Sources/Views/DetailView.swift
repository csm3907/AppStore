import Domain
import SwiftUI

public struct DetailView: View {
    public let app: AppInfo
    public let showsFullScreenButton: Bool
    public let showsCloseButton: Bool
    public let onFullScreen: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        app: AppInfo,
        showsFullScreenButton: Bool = false,
        showsCloseButton: Bool = true,
        onFullScreen: @escaping () -> Void = {}
    ) {
        self.app = app
        self.showsFullScreenButton = showsFullScreenButton
        self.showsCloseButton = showsCloseButton
        self.onFullScreen = onFullScreen
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        AsyncImage(url: app.iconUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .failure:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(app.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(app.seller)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(app.genre)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    if let rating = app.rating {
                        HStack(spacing: 8) {
                            Text(String(format: "%.1f", rating))
                                .font(.headline)
                            if let ratingCount = app.ratingCount {
                                Text("평점 \(formatCount(ratingCount))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text(app.description)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if !app.screenshotUrls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(app.screenshotUrls, id: \.self) { url in
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 200, height: 420)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 420)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.secondary.opacity(0.2))
                                                .frame(width: 200, height: 420)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("App Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showsCloseButton {
                        Button("닫기") {
                            dismiss()
                        }
                    } else {
                        EmptyView()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if showsFullScreenButton {
                        Button("전체화면") {
                            onFullScreen()
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }

    private func formatCount(_ count: Int) -> String {
        let value = Double(count)

        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        }

        if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        }

        return String(count)
    }
}
