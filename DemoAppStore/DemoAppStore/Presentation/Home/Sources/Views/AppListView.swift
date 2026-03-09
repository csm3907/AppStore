import Core
import Domain
import SwiftUI
import UniformTypeIdentifiers

struct AppListView: View {
    // MARK: - Variables
    @ObservedObject var viewModel: HomeViewModel
    @Binding var apps: [AppInfo]
    @Binding var selectedIndex: Int
    @Binding var memoText: String
    @Binding var isShowingMemoEditor: Bool
    @Binding var isShowingMemoOnDrag: Bool
    @Binding var selectedApp: AppInfo?
    @Binding var selectedMemo: AppInfo?
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    @State private var showPreviousCard = false

    private let tabs = HomeTab.allCases

    // MARK: - Views
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                List {
                    ForEach(apps, id: \.id) { app in
                        let memoText = viewModel.memo(for: app.id)?.trimmed ?? ""
                        AppRowView(
                            app: app,
                            hasMemo: !memoText.isEmpty,
                            onIconTap: {
                                selectedMemo = app
                                self.memoText = viewModel.memo(for: app.id)?.trimmed ?? ""
                                isShowingMemoEditor = true
                                isShowingMemoOnDrag = false
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedApp = app
                        }
                        .onDrop(of: [UTType.text.identifier], isTargeted: nil) { providers in
                            handleDrop(providers: providers, appId: app.id)
                        }
                        .onAppear {
                            if app.id == apps.last?.id {
                                onLoadMore()
                            }
                        }
                    }

                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: 180)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: showPreviousCard ? .leading : .trailing),
                        removal: .move(edge: showPreviousCard ? .trailing : .leading)
                    )
                )
            }
            .gesture(horizontalSwipeGesture)
        }
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 100

                if value.translation.width < -threshold {
                    // left swipe
                    showPreviousCard = false

                    withAnimation(.snappy) {
                        selectedIndex = (selectedIndex + 1) % tabs.count
                    }

                } else if value.translation.width > threshold {
                    // right swipe
                    showPreviousCard = true

                    withAnimation(.snappy) {
                        selectedIndex = (selectedIndex - 1 + tabs.count) % tabs.count
                    }
                }
            }
    }

    private func handleDrop(providers: [NSItemProvider], appId: Int) -> Bool {
        guard !providers.isEmpty else { return false }

        let provider = providers[0]
        if provider.canLoadObject(ofClass: NSString.self) {
            _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                guard let value = object as? String else { return }
                Task { @MainActor in
                    viewModel.saveMemo(value, for: appId)
                }
            }
        } else {
            viewModel.saveMemo(memoText, for: appId)
        }

        memoText = ""
        isShowingMemoEditor = false
        isShowingMemoOnDrag = false
        return true
    }

}

private struct AppRowView: View {
    let app: AppInfo
    let hasMemo: Bool
    let onIconTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onIconTap()
            } label: {
                CachedAsyncImage(url: app.iconUrl) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 56, height: 56)
                } failure: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 56, height: 56)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)

                Text(app.seller)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(app.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let rating = app.rating {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", rating))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let ratingCount = app.ratingCount {
                        Text("평점 \(formatCount(ratingCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("평점")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Image(systemName: "note.text")
                .symbolVariant(hasMemo ? .fill : .none)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(hasMemo ? .accentColor : .secondary)
        }
        .padding(.vertical, 6)
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
