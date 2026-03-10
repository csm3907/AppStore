import Core
import Domain
import SwiftUI

public struct DetailView: View {
    public let app: AppInfoEntity
    public let showsFullScreenButton: Bool
    public let showsCloseButton: Bool
    public let onFullScreen: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("memo.store.data") private var memoStoreData: Data = Data()

    public init(
        app: AppInfoEntity,
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
                        CachedAsyncImage(url: app.iconUrl) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(width: 80, height: 80)
                        } failure: {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 80, height: 80)
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

                    if !memoText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("메모")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(memoText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }

                    Text(app.description)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if !app.screenshotUrls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(app.screenshotUrls, id: \.self) { url in
                                    CachedAsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 420)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    } placeholder: {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .frame(width: 200, height: 420)
                                    } failure: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(width: 200, height: 420)
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

    private var memoText: String {
        guard !memoStoreData.isEmpty else { return "" }
        let store = (try? JSONDecoder().decode([Int: String].self, from: memoStoreData)) ?? [:]
        return store[app.id]?.trimmed ?? ""
    }
}
