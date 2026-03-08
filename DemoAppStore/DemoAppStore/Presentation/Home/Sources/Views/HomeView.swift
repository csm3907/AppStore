import SwiftUI
import UIKit
import Core

public struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel = HomeViewModel()
    @State private var selectedIndex: Int = 0
    private let tabs = HomeTab.allCases

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            InfiniteTabMenuView(tabs: tabs, selectedIndex: $selectedIndex)

            AppListView(apps: viewModel.apps, selectedIndex: $selectedIndex)
        }
        .task {
            await viewModel.fetchApps(genreId: tabs[selectedIndex].genreId)
        }
        .onChange(of: selectedIndex) { newIndex in
            Task {
                await viewModel.fetchApps(genreId: tabs[newIndex].genreId)
            }
        }
    }
}

