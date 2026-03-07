import SwiftUI
import Core

public struct HomeView: View {
    enum HomeTab: String, CaseIterable, Identifiable {
        case featured = "추천"
        case topCharts = "차트"
        case categories = "카테고리"
        case deals = "할인"
        case newApps = "신규"
        case editorsChoice = "에디터 추천"
        case kids = "키즈"
        case productivity = "생산성"
        case social = "소셜"

        var id: String { rawValue }
    }

    @State private var selectedTab: HomeTab = .featured
    @State private var selectedIndex: Int = 1
    @State private var isAdjustingIndex = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ScrollableTabBar(tabs: tabs, selection: $selectedTab, title: { $0.rawValue })
                .onChange(of: selectedTab) { newValue in
                    guard let index = tabs.firstIndex(of: newValue) else { return }
                    let targetIndex = index + 1
                    if selectedIndex != targetIndex {
                        selectedIndex = targetIndex
                    }
                }

            TabView(selection: $selectedIndex) {
                ForEach(loopedTabs.indices, id: \.self) { index in
                    let tab = loopedTabs[index]
                    TabContentView(title: tab.rawValue)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedIndex) { newValue in
                updateSelection(for: newValue)
            }
        }
        .onAppear {
            updateSelection(for: selectedIndex)
        }
    }

    private var tabs: [HomeTab] {
        HomeTab.allCases
    }
    private var loopedTabs: [HomeTab] {
        guard tabs.count > 1, let first = tabs.first, let last = tabs.last else {
            return tabs
        }
        return [last] + tabs + [first]
    }

    private func updateSelection(for index: Int) {
        guard !isAdjustingIndex else { return }
        guard !loopedTabs.isEmpty else { return }

        let lastIndex = loopedTabs.count - 1
        var effectiveIndex = index
        var needsWrap = false

        if index == 0 {
            effectiveIndex = tabs.count
            needsWrap = true
        } else if index == lastIndex {
            effectiveIndex = 1
            needsWrap = true
        }

        selectedTab = loopedTabs[effectiveIndex]

        if needsWrap {
            isAdjustingIndex = true
            DispatchQueue.main.async {
                selectedIndex = effectiveIndex
                isAdjustingIndex = false
            }
        }
    }
}

