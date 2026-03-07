import SwiftUI

struct TabContentView: View {
    let title: String
    let count: Int
    @Binding var selectedIndex: Int

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    Text("\(title) 콘텐츠")
                        .font(.system(size: 22, weight: .bold))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: max(160, proxy.size.height * 0.4))
                        .overlay(
                            Text("Swipe ◀︎ ▶︎")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        )

                    Spacer(minLength: 0)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > abs(dy) else { return }
                        let threshold: CGFloat = 60
                        if dx <= -threshold {
                            moveSelection(by: 1)
                        } else if dx >= threshold {
                            moveSelection(by: -1)
                        }
                    }
            )
        }
    }

    private func moveSelection(by delta: Int) {
        guard count > 0 else { return }
        let newIndex = (selectedIndex + delta + count) % count
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedIndex = newIndex
        }
    }
}
