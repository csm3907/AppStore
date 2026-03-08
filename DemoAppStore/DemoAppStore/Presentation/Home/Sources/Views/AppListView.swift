import Domain
import SwiftUI

struct AppListView: View {
    // MARK: - Variables
    let apps: [AppInfo]
    @Binding var selectedIndex: Int
    @State private var showPreviousCard = false

    private let tabs = HomeTab.allCases

    // MARK: - Views
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    if index == selectedIndex {
                        RoundedRectangle(cornerRadius: 24)
                            .overlay {
                                Text(tabs[index].description)
                                    .font(.system(size: 78, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: showPreviousCard ? .leading : .trailing),
                                    removal: .move(edge: showPreviousCard ? .trailing : .leading)
                                )
                            )
                            .frame(height: 240)
                            .padding(24)
                    }
                }
            }
            .gesture(
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
            )

            List(apps, id: \.id) { app in
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: app.iconUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 56, height: 56)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 56, height: 56)
                        @unknown default:
                            EmptyView()
                        }
                    }

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
                }
                .padding(.vertical, 6)
            }
            .listStyle(.plain)
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
