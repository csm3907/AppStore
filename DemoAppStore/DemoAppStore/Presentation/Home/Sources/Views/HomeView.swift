import SwiftUI
import UIKit
import Core
import Domain
import PresentationDetail

public struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel = HomeViewModel()
    @State private var selectedIndex: Int = 0
    @State private var isShowingMemoEditor = false
    @State private var isShowingMemoOnDrag = false
    @State private var memoText = ""
    @State private var selectedApp: AppInfo?
    @State private var fullScreenApp: AppInfo?
    @State private var pendingFullScreenApp: AppInfo?
    private let tabs = HomeTab.allCases

    public init() {}

    public var body: some View {
        content
            .task {
                await viewModel.fetchApps(genreId: tabs[selectedIndex].genreId)
            }
            .onChange(of: selectedIndex) { newIndex in
                Task {
                    await viewModel.fetchApps(genreId: tabs[newIndex].genreId)
                }
            }
            .sheet(item: $selectedApp, onDismiss: handleSheetDismiss) { app in
                DetailView(
                    app: app,
                    showsFullScreenButton: true,
                    showsCloseButton: true
                ) {
                    pendingFullScreenApp = app
                    selectedApp = nil
                }
            }
            .fullScreenCover(item: $fullScreenApp) { app in
                DetailView(
                    app: app,
                    showsFullScreenButton: false,
                    showsCloseButton: true
                ) {}
            }
    }

    @ViewBuilder
    private var content: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(.stack)
        }
    }

    private var mainContent: some View {
        ZStack {
            VStack(spacing: 0) {
                InfiniteTabMenuView(tabs: tabs, selectedIndex: $selectedIndex)

                AppListView(
                    apps: viewModel.apps,
                    selectedIndex: $selectedIndex,
                    memoText: $memoText,
                    isShowingMemoEditor: $isShowingMemoEditor,
                    isShowingMemoOnDrag: $isShowingMemoOnDrag,
                    selectedApp: $selectedApp
                )
            }

            if isShowingMemoEditor {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        memoText = ""
                        isShowingMemoEditor = false
                        isShowingMemoOnDrag = false
                    }

                MemoEditorView(text: $memoText, isShowingMemoOnDrag: $isShowingMemoOnDrag) {
                    memoText = ""
                    isShowingMemoEditor = false
                    isShowingMemoOnDrag = false
                }
                .opacity(isShowingMemoOnDrag ? 0 : 1)
                .transition(.scale)
                .offset(y: -80)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingMemoEditor)
        .navigationTitle("AppStore")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingMemoEditor = true
                    isShowingMemoOnDrag = false
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func handleSheetDismiss() {
        if let pending = pendingFullScreenApp {
            fullScreenApp = pending
            pendingFullScreenApp = nil
        }
    }
}

