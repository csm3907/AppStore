import SwiftUI

struct MemoEditorView: View {
    @Binding var text: String
    @Binding var isShowingMemoOnDrag: Bool
    let appName: String?
    var onSave: (() -> Void)?
    var onCancel: () -> Void

    init(
        text: Binding<String>,
        isShowingMemoOnDrag: Binding<Bool>,
        appName: String? = nil,
        onSave: (() -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        _text = text
        _isShowingMemoOnDrag = isShowingMemoOnDrag
        self.appName = appName
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("메모")
                    .font(.headline)
                Spacer()
                
                if appName != nil {
                    Button("저장") {
                        onSave?()
                    }
                    .foregroundStyle(.secondary)
                }

                Button("취소") {
                    onCancel()
                }
                .foregroundStyle(.secondary)
            }

            if let appName, !appName.isEmpty {
                Text(appName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $text)
                .frame(height: 160)
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: text) { newValue in
                    if newValue.count > 100 {
                        text = String(newValue.prefix(100))
                    }
                }
            if appName == nil {
                HStack {
                    Image(systemName: "hand.draw")
                    Text("메모를 길게 눌러 드래그")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(Capsule())
                .onDrag {
                    isShowingMemoOnDrag = true
                    return NSItemProvider(object: text as NSString)
                } preview: {
                    Text(text.isEmpty ? "메모" : text)
                        .font(.caption)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .opacity(isShowingMemoOnDrag ? 0 : 1)
        .padding(16)
        .frame(maxWidth: 340)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12)
    }
}
