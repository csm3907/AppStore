//
//  ScrollableTabBar.swift
//  Core
//
//  Created by 최승민 on 3/7/26.
//

import SwiftUI

public struct ScrollableTabBar<Tab: Identifiable & Equatable>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    let title: (Tab) -> String

    @State private var currentIndex: Int = 0

    public init(tabs: [Tab], selection: Binding<Tab>, title: @escaping (Tab) -> String) {
        self.tabs = tabs
        self._selection = selection
        self.title = title
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 16) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        Button {
                            selection = tab
                        } label: {
                            VStack(spacing: 6) {
                                Text(title(tab))
                                    .font(.system(size: 16, weight: selection == tab ? .semibold : .regular))
                                    .foregroundStyle(selection == tab ? .primary : .secondary)

                                Capsule()
                                    .fill(selection == tab ? Color.primary : Color.clear)
                                    .frame(height: 2)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .onAppear {
                    let target = targetIndex(for: selection, from: nil)
                    currentIndex = target
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
                .onChange(of: selection) { newValue in
                    let target = targetIndex(for: newValue, from: currentIndex)
                    currentIndex = target
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
    }

    private func targetIndex(for tab: Tab, from currentIndex: Int?) -> Int {
        let baseCount = max(1, tabs.count / 3)
        let baseIndex = tabs.prefix(baseCount).firstIndex(where: { $0.id == tab.id }) ?? 0
        guard tabs.count >= baseCount * 3 else { return baseIndex }

        guard let currentIndex else {
            return baseIndex + baseCount
        }

        let currentBase = currentIndex % baseCount
        var delta = baseIndex - currentBase
        if delta > baseCount / 2 {
            delta -= baseCount
        } else if delta < -baseCount / 2 {
            delta += baseCount
        }

        var target = currentIndex + delta
        if target < 0 {
            target += baseCount
        } else if target >= tabs.count {
            target -= baseCount
        }
        return target
    }

}

public struct ScrollableTabContainer<Tab: Identifiable & Equatable, Content: View>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    let title: (Tab) -> String
    let content: (Tab) -> Content

    private let tabBarMaxWidth: CGFloat = 320
    private var tabCount: Int { tabs.count }
    private var repeatedTabs: [Tab] { tabs + tabs + tabs }

    // ✅ 초기값을 생성자에서 계산해서 State에 주입
    @State private var selectedIndex: Int


    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        title: @escaping (Tab) -> String,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.tabs = tabs
        self._selection = selection
        self.title = title
        self.content = content

        // ✅ 중간 세트의 selection 위치로 초기화
        let initialIndex = tabs.firstIndex(where: { $0.id == selection.wrappedValue.id }) ?? 0
        self._selectedIndex = State(initialValue: tabs.count + initialIndex)
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ScrollableTabBar(tabs: repeatedTabs, selection: $selection, title: title)
            }

            TabView(selection: $selectedIndex) {
                ForEach(0..<repeatedTabs.count, id: \.self) { index in
                    content(repeatedTabs[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedIndex) { newIndex in
                let realIndex = newIndex % tabCount
                if selection != tabs[realIndex] {
                    selection = tabs[realIndex]
                }

                let isInFirstSet = newIndex < tabCount
                let isInLastSet  = newIndex >= tabCount * 2

                if isInFirstSet || isInLastSet {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selectedIndex = tabCount + realIndex
                    }
                }
            }
            .onChange(of: selection) { newValue in
                guard let target = tabs.firstIndex(of: newValue) else { return }
                let current = selectedIndex % tabCount
                guard current != target else { return }
                let currentSet = selectedIndex / tabCount
                selectedIndex = currentSet * tabCount + target
            }

        }
    }
}

