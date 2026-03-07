import SwiftUI

struct TabContentView: View {
    let title: String

    var body: some View {
        GeometryReader { proxy in
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

                Spacer()
            }
            .padding(24)
        }
    }
}
