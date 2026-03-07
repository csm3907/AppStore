import SwiftUI
import UIKit

// MARK: - InfiniteCollectionTabBar

public struct InfiniteCollectionTabBar<Tab: Identifiable & Equatable, TabItem: View>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    let tabItem: (Tab, Bool) -> TabItem

    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        @ViewBuilder tabItem: @escaping (Tab, Bool) -> TabItem
    ) {
        self.tabs = tabs
        self._selection = selection
        self.tabItem = tabItem
    }

    public var body: some View {
        _InfiniteCollectionTabBar(
            tabs: tabs,
            selection: $selection,
            tabItem: { tab, isSelected in
                AnyView(tabItem(tab, isSelected))
            }
        )
        .frame(height: 46)
    }
}

private struct _InfiniteCollectionTabBar<Tab: Identifiable & Equatable>: UIViewRepresentable {
    let tabs: [Tab]
    @Binding var selection: Tab
    let tabItem: (Tab, Bool) -> AnyView

    func makeCoordinator() -> Coordinator {
        Coordinator(tabs: tabs, selection: $selection, tabItem: tabItem)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = context.coordinator.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: context.coordinator.sectionInset,
            bottom: 0,
            right: context.coordinator.sectionInset
        )

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(TabHostingCell.self, forCellWithReuseIdentifier: TabHostingCell.reuseId)

        context.coordinator.collectionView = collectionView
        context.coordinator.prepareLayout()
        context.coordinator.scrollToInitialPosition(animated: false)

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.update(tabs: tabs, selection: selection)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
        private(set) var tabs: [Tab]
        @Binding private var selection: Tab
        private let tabItem: (Tab, Bool) -> AnyView

        private let repeatCount: Int = 3
        private var baseCount: Int { tabs.count }
        private var totalCount: Int { baseCount * repeatCount }

        weak var collectionView: UICollectionView?

        private let itemHorizontalPadding: CGFloat = 12
        private let itemHeight: CGFloat = 32
        let itemSpacing: CGFloat = 16
        let sectionInset: CGFloat = 16

        private var itemWidths: [CGFloat] = []
        private var loopWidth: CGFloat = 0
        private var currentIndex: Int = 0
        private var isRecentering = false
        private var isExternalUpdate = false
        private var lastSelection: Tab?

        init(tabs: [Tab], selection: Binding<Tab>, tabItem: @escaping (Tab, Bool) -> AnyView) {
            self.tabs = tabs
            self._selection = selection
            self.tabItem = tabItem
        }

        func prepareLayout() {
            measureItemWidths()
        }

        func update(tabs: [Tab], selection: Tab) {
            let tabsChanged = tabs.count != self.tabs.count || tabs.first?.id != self.tabs.first?.id
            self.tabs = tabs

            if tabsChanged {
                measureItemWidths()
                collectionView?.reloadData()
            }

            if lastSelection != selection {
                lastSelection = selection
                collectionView?.reloadData()
            }

            guard !isExternalUpdate else { return }
            scrollToSelectionIfNeeded(selection)
        }

        // MARK: - DataSource

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return totalCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabHostingCell.reuseId, for: indexPath) as? TabHostingCell else {
                return UICollectionViewCell()
            }

            let tab = tabs[indexPath.item % max(1, baseCount)]
            let isSelected = (tab == selection)
            cell.configure(view: tabItem(tab, isSelected))
            return cell
        }

        // MARK: - Delegate

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let tab = tabs[indexPath.item % max(1, baseCount)]
            isExternalUpdate = true
            selection = tab
            isExternalUpdate = false
            currentIndex = indexPath.item
            scrollToIndex(indexPath.item, animated: true)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            guard baseCount > 0 else { return .zero }
            let width = itemWidths[indexPath.item % baseCount]
            return CGSize(width: width, height: itemHeight)
        }

        // MARK: - Scroll

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard loopWidth > 0, !isRecentering else { return }

            let offset = scrollView.contentOffset.x
            let lowerBound = loopWidth * 0.5
            let upperBound = loopWidth * 1.5

            if offset < lowerBound {
                isRecentering = true
                scrollView.contentOffset.x += loopWidth
                currentIndex = normalizeIndex(currentIndex + baseCount)
                isRecentering = false
            } else if offset > upperBound {
                isRecentering = true
                scrollView.contentOffset.x -= loopWidth
                currentIndex = normalizeIndex(currentIndex - baseCount)
                isRecentering = false
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                updateSelectionFromCenter()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            updateSelectionFromCenter()
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            guard let collectionView else { return }
            let nearest = nearestIndexToCenter(in: collectionView) ?? currentIndex

            let deltaX = targetContentOffset.pointee.x - scrollView.contentOffset.x
            let direction: Int
            if deltaX > 0 {
                direction = 1
            } else if deltaX < 0 {
                direction = -1
            } else if velocity.x > 0 {
                direction = 1
            } else if velocity.x < 0 {
                direction = -1
            } else {
                direction = 0
            }

            let nextIndex = direction == 0 ? nearest : (nearest + direction)
            let clamped = normalizeIndex(nextIndex)
            if let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: clamped, section: 0)) {
                let targetX = attributes.center.x - collectionView.bounds.width / 2
                targetContentOffset.pointee = CGPoint(x: targetX, y: 0)
            }
        }

        // MARK: - Helpers

        private func measureItemWidths() {
            guard baseCount > 0 else {
                itemWidths = []
                loopWidth = 0
                return
            }

            itemWidths = tabs.map { tab in
                let host = UIHostingController(rootView: tabItem(tab, false))
                let size = host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: itemHeight))
                return ceil(size.width) + itemHorizontalPadding * 2
            }

            let itemsWidth = itemWidths.reduce(0, +)
            let spacingWidth = itemSpacing * CGFloat(max(0, baseCount - 1))
            loopWidth = itemsWidth + spacingWidth + sectionInset * 2
        }

        func scrollToInitialPosition(animated: Bool) {
            guard baseCount > 0 else { return }
            let baseIndex = tabs.firstIndex(where: { $0.id == selection.id }) ?? 0
            let target = baseCount + baseIndex
            currentIndex = target
            scrollToIndex(target, animated: animated)
        }

        private func scrollToSelectionIfNeeded(_ selection: Tab) {
            guard baseCount > 0 else { return }
            let baseIndex = tabs.firstIndex(where: { $0.id == selection.id }) ?? 0
            let target = nearestIndex(for: baseIndex)
            if target != currentIndex {
                currentIndex = target
                scrollToIndex(target, animated: true)
            }
        }

        private func nearestIndex(for baseIndex: Int) -> Int {
            guard baseCount > 0 else { return baseIndex }
            let currentBase = currentIndex % baseCount
            var delta = baseIndex - currentBase
            if delta > baseCount / 2 {
                delta -= baseCount
            } else if delta < -baseCount / 2 {
                delta += baseCount
            }
            var target = currentIndex + delta
            if target < 0 { target += baseCount }
            if target >= totalCount { target -= baseCount }
            return target
        }

        private func scrollToIndex(_ index: Int, animated: Bool) {
            guard let collectionView else { return }
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        }

        private func updateSelectionFromCenter() {
            guard let collectionView else { return }
            guard let indexPath = nearestIndexToCenter(in: collectionView) else { return }

            currentIndex = indexPath
            let tab = tabs[indexPath % max(1, baseCount)]
            if tab != selection {
                isExternalUpdate = true
                selection = tab
                isExternalUpdate = false
            }
            lastSelection = tab
            collectionView.reloadData()
        }

        private func nearestIndexToCenter(in collectionView: UICollectionView) -> Int? {
            let centerPoint = CGPoint(x: collectionView.bounds.midX + collectionView.contentOffset.x, y: collectionView.bounds.midY)
            var nearest: IndexPath?
            var minDistance = CGFloat.greatestFiniteMagnitude
            for indexPath in collectionView.indexPathsForVisibleItems {
                if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
                    let distance = abs(attributes.center.x - centerPoint.x)
                    if distance < minDistance {
                        minDistance = distance
                        nearest = indexPath
                    }
                }
            }
            return nearest?.item
        }

        private func normalizeIndex(_ index: Int) -> Int {
            guard totalCount > 0 else { return 0 }
            var value = index
            if value < 0 { value += totalCount }
            if value >= totalCount { value -= totalCount }
            return value
        }
    }
}

private final class TabHostingCell: UICollectionViewCell {
    static let reuseId = "InfiniteTabHostingCell"

    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(view: AnyView) {
        if let hostingController {
            hostingController.rootView = view
            hostingController.view.invalidateIntrinsicContentSize()
        } else {
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            hostingController = controller
            contentView.addSubview(controller.view)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }
}
