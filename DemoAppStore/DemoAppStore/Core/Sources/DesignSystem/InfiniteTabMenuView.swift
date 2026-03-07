//
//  Test.swift
//  Core
//
//  Created by 최승민 on 3/7/26.
//

import SwiftUI
import UIKit

// MARK: - InfiniteTabMenuView (SwiftUI Entry Point)
/// 좌우로 진짜 무한 스크롤되는 탭 메뉴 컴포넌트
///
/// Tab 타입 조건: Hashable & CustomStringConvertible
/// → 각 Feature의 enum을 그대로 넘길 수 있습니다.
///
/// 사용 예:
///   enum HomeTab: String, CaseIterable, CustomStringConvertible {
///       case today, games, apps, arcade, search
///       var description: String { rawValue }
///   }
///
///   InfiniteTabMenuView(tabs: HomeTab.allCases, selectedIndex: $selectedIndex)
public struct InfiniteTabMenuView<Tab: Hashable & CustomStringConvertible>: View {

    let tabs: [Tab]
    @Binding var selectedIndex: Int

    public init(tabs: [Tab], selectedIndex: Binding<Int>) {
        self.tabs = tabs
        self._selectedIndex = selectedIndex
    }

    public var body: some View {
        VStack(spacing: 0) {
            _InfiniteTabScrollView(tabs: tabs, selectedIndex: $selectedIndex)
                .frame(height: 46)

            Divider()
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - UIViewRepresentable Bridge

private struct _InfiniteTabScrollView<Tab: Hashable & CustomStringConvertible>: UIViewRepresentable {

    let tabs: [Tab]
    @Binding var selectedIndex: Int

    func makeCoordinator() -> Coordinator<Tab> {
        Coordinator(tabs: tabs, selectedIndex: $selectedIndex)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = context.coordinator.scrollView
        context.coordinator.setup(in: scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.updateSelection(index: selectedIndex)
    }

    // MARK: - Coordinator
    final class Coordinator<TabItem: Hashable & CustomStringConvertible>: NSObject, UIScrollViewDelegate {

        let tabs: [TabItem]
        @Binding var selectedIndex: Int

        // ── 무한 스크롤 핵심 상수 ───────────────────────────
        private let repeatCount = 5
        private var totalCount: Int { tabs.count * repeatCount }
        /// 초기 시작 위치: 전체의 정중앙 루프
        private var centerLoopIndex: Int { (repeatCount / 2) * tabs.count }

        // ── UIKit 뷰 ─────────────────────────────────────────
        let scrollView = UIScrollView()
        private let contentView = UIView()
        private var tabButtons: [UIButton] = []

        // ── 탭 너비 캐시 ─────────────────────────────────────
        private var tabWidths: [CGFloat] = []
        private var tabXOffsets: [CGFloat] = []

        // ── 상태 ─────────────────────────────────────────────
        private var currentTabIndex: Int = 0
        private var currentGlobalIndex: Int = 0
        private var isExternalUpdate = false
        private var isProgrammaticScroll = false

        private let tabHeight: CGFloat = 44
        private let tabPadding: CGFloat = 16

        init(tabs: [TabItem], selectedIndex: Binding<Int>) {
            self.tabs = tabs
            self._selectedIndex = selectedIndex
        }

        // MARK: - Setup
        func setup(in scrollView: UIScrollView) {
            scrollView.delegate = self
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.backgroundColor = .clear
            scrollView.decelerationRate = .normal

            measureTabWidths()

            let loopWidth = loopTotalWidth()
            let totalWidth = loopWidth * CGFloat(repeatCount)

            contentView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: tabHeight)
            scrollView.addSubview(contentView)
            scrollView.contentSize = contentView.bounds.size

            for globalIndex in 0..<totalCount {
                let tabIndex = globalIndex % tabs.count
                let loopIndex = globalIndex / tabs.count
                let x = CGFloat(loopIndex) * loopWidth + tabXOffsets[tabIndex]

                let btn = makeTabButton(tab: tabs[tabIndex], globalIndex: globalIndex, x: x)
                contentView.addSubview(btn)
                tabButtons.append(btn)
            }
            
            currentTabIndex = selectedIndex
            currentGlobalIndex = centerLoopIndex + selectedIndex

            let initialGlobal = centerLoopIndex + selectedIndex
            DispatchQueue.main.async {
                self.scrollToGlobalIndex(initialGlobal, animated: false)
                self.updateButtonStyles()
            }
        }

        // MARK: - 탭 너비 측정 (CustomStringConvertible의 description 사용)
        private func measureTabWidths() {
            tabWidths = []
            tabXOffsets = []
            var x: CGFloat = 0
            for tab in tabs {
                let size = (tab.description as NSString).size(
                    withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold)]
                )
                let width = ceil(size.width) + tabPadding * 2
                tabXOffsets.append(x)
                tabWidths.append(width)
                x += width
            }
        }

        // MARK: - 버튼 생성
        private func makeTabButton(tab: TabItem, globalIndex: Int, x: CGFloat) -> UIButton {
            let tabIndex = globalIndex % tabs.count
            let btn = UIButton(type: .custom)
            btn.frame = CGRect(x: x, y: 0, width: tabWidths[tabIndex], height: tabHeight)
            btn.setTitle(tab.description, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.tag = globalIndex
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            return btn
        }

        // MARK: - 탭 탭 액션
        @objc private func tabTapped(_ sender: UIButton) {
            let globalIndex = sender.tag
            guard globalIndex != currentGlobalIndex else { return }

            applySelection(globalIndex: globalIndex, animated: true)
        }

        // MARK: - 외부 selectedIndex 변경 반영
        func updateSelection(index tabIndex: Int) {
            guard !isExternalUpdate,
                  tabIndex < tabs.count,
                  tabIndex != currentTabIndex else { return }

            if scrollView.isDragging || scrollView.isDecelerating || scrollView.isTracking {
                return
            }

            let targetGlobal = nearestGlobalIndex(for: tabIndex, from: currentGlobalIndex)
            print("current: \(currentGlobalIndex), target: \(targetGlobal)")
            applySelection(globalIndex: targetGlobal, animated: true)
        }

        // MARK: - 스크롤 to globalIndex
        private func scrollToGlobalIndex(_ globalIndex: Int, animated: Bool) {
            guard globalIndex < tabButtons.count else { return }
            guard scrollView.bounds.width > 0, scrollView.contentSize.width > 0 else {
                DispatchQueue.main.async { [weak self] in
                    self?.scrollToGlobalIndex(globalIndex, animated: animated)
                }
                return
            }

            let btn = tabButtons[globalIndex]
            let targetX = btn.frame.midX - scrollView.bounds.width / 2
            let clampedX = max(0, min(targetX, scrollView.contentSize.width - scrollView.bounds.width))

            isProgrammaticScroll = true
            scrollView.setContentOffset(CGPoint(x: clampedX, y: 0), animated: animated)
            if !animated {
                isProgrammaticScroll = false
            }
        }

        // MARK: - 버튼 스타일
        private func updateButtonStyles() {
            for btn in tabButtons {
                let isSelected = (btn.tag % tabs.count) == currentTabIndex
                btn.titleLabel?.font = .systemFont(ofSize: 15, weight: isSelected ? .semibold : .regular)
                btn.setTitleColor(isSelected ? .label : .secondaryLabel, for: .normal)
            }
        }

        // MARK: - 루프 1세트 전체 너비
        private func loopTotalWidth() -> CGFloat {
            guard !tabWidths.isEmpty else { return 0 }
            return tabXOffsets.last! + tabWidths.last!
        }

        // MARK: - UIScrollViewDelegate: 무한 루프 핵심 ⭐️
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard adjustForInfiniteLoopIfNeeded(scrollView) else { return }
            guard !isProgrammaticScroll else { return }

            let detectedGlobalIndex = globalIndexAtCenter(scrollView)
            if detectedGlobalIndex != currentGlobalIndex {
                syncSelectionFromScroll(globalIndex: detectedGlobalIndex)
            }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isProgrammaticScroll = false
        }

        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            isProgrammaticScroll = false
        }

        // MARK: - Selection helpers
        private func applySelection(globalIndex: Int, animated: Bool) {
            guard tabs.count > 0 else { return }
            let resolvedGlobal = normalizeGlobalIndex(globalIndex)
            let tabIndex = resolvedGlobal % tabs.count
            currentTabIndex = tabIndex
            currentGlobalIndex = resolvedGlobal

            setSelectedIndexSafely(tabIndex)

            scrollToGlobalIndex(resolvedGlobal, animated: animated)
            updateUI(tabIndex: tabIndex, animated: animated)
        }

        private func syncSelectionFromScroll(globalIndex: Int) {
            guard tabs.count > 0 else { return }
            let resolvedGlobal = normalizeGlobalIndex(globalIndex)
            let tabIndex = resolvedGlobal % tabs.count
            currentTabIndex = tabIndex
            currentGlobalIndex = resolvedGlobal
            setSelectedIndexSafely(tabIndex)
            updateUI(tabIndex: tabIndex, animated: false)
        }

        private func updateUI(tabIndex: Int, animated: Bool) {
            updateButtonStyles()
        }

        private func setSelectedIndexSafely(_ tabIndex: Int) {
            DispatchQueue.main.async {
                self.isExternalUpdate = true
                self.selectedIndex = tabIndex
                self.isExternalUpdate = false
            }
        }

        private func globalIndexAtCenter(_ scrollView: UIScrollView) -> Int {
            let loopWidth = loopTotalWidth()
            guard loopWidth > 0 else { return currentGlobalIndex }

            let centerX = scrollView.contentOffset.x + scrollView.bounds.width / 2
            let loopIndex = Int(centerX / loopWidth)
            let clampedLoop = max(0, min(loopIndex, repeatCount - 1))
            let tabIndex = tabIndexAtX(centerX)
            return clampedLoop * tabs.count + tabIndex
        }

        private func normalizeGlobalIndex(_ index: Int) -> Int {
            guard totalCount > 0 else { return 0 }
            var value = index
            if value < 0 { value += totalCount }
            if value >= totalCount { value -= totalCount }
            return value
        }

        private func nearestGlobalIndex(for tabIndex: Int, from currentGlobal: Int) -> Int {
            guard tabs.count > 0 else { return 0 }
            let currentLoopBase = currentGlobal - (currentGlobal % tabs.count)
            let candidates = [
                currentLoopBase - tabs.count + tabIndex,
                currentLoopBase + tabIndex,
                currentLoopBase + tabs.count + tabIndex
            ]
            let target = candidates.min { lhs, rhs in
                abs(lhs - currentGlobal) < abs(rhs - currentGlobal)
            } ?? (currentLoopBase + tabIndex)
            return normalizeGlobalIndex(target)
        }

        private func adjustForInfiniteLoopIfNeeded(_ scrollView: UIScrollView) -> Bool {
            let loopWidth = loopTotalWidth()
            guard loopWidth > 0 else { return false }

            let offset = scrollView.contentOffset.x
            let midLoop = CGFloat(repeatCount / 2)
            let lowerBound = loopWidth * (midLoop - 1)
            let upperBound = loopWidth * (midLoop + 1)

            if offset < lowerBound {
                scrollView.contentOffset.x += loopWidth
                currentGlobalIndex = normalizeGlobalIndex(currentGlobalIndex + tabs.count)
            } else if offset > upperBound {
                scrollView.contentOffset.x -= loopWidth
                currentGlobalIndex = normalizeGlobalIndex(currentGlobalIndex - tabs.count)
            }

            return true
        }

        // MARK: - X 좌표 → 탭 인덱스 변환
        private func tabIndexAtX(_ x: CGFloat) -> Int {
            let loopWidth = loopTotalWidth()
            guard loopWidth > 0 else { return 0 }

            let offsetInLoop = x.truncatingRemainder(dividingBy: loopWidth)
            for i in stride(from: tabs.count - 1, through: 0, by: -1) {
                if offsetInLoop >= tabXOffsets[i] {
                    return i
                }
            }
            return 0
        }
    }
}

// MARK: - Preview
#Preview {
    _InfiniteTabMenuPreview()
}

private struct _InfiniteTabMenuPreview: View {

    // Preview용 enum — 실제 프로젝트에서는 각 Feature 레이어에 선언
    enum HomeTab: String, CaseIterable, CustomStringConvertible {
        case today   = "투데이"
        case games   = "게임"
        case apps    = "앱"
        case arcade  = "아케이드"
        case search  = "검색"

        var description: String { rawValue }
    }

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            InfiniteTabMenuView(tabs: HomeTab.allCases, selectedIndex: $selectedIndex)

            ZStack {
                Color(uiColor: .systemGroupedBackground)
                VStack(spacing: 8) {
                    Text(HomeTab.allCases[selectedIndex].description)
                        .font(.largeTitle.bold())
                    Text("← 어느 방향으로든 무한 스크롤 →")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
