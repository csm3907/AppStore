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
    @State private var selectedMemo: AppInfo?
    @State private var fullScreenApp: AppInfo?
    @State private var pendingFullScreenApp: AppInfo?
    private let tabs = HomeTab.allCases

    public init() {}

    public var body: some View {
        content
            .task {
                viewModel.requestFetch(term: tabs[selectedIndex].term, genreId: tabs[selectedIndex].genreId)
            }
            .onChange(of: selectedIndex) { newIndex in
                viewModel.requestFetch(term: tabs[newIndex].term, genreId: tabs[newIndex].genreId)
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
                InfiniteTabMenuView(tabs: tabs, selectedIndex: $selectedIndex, isLoading: $viewModel.isLoading) { index in
                    viewModel.requestFetch(term: tabs[index].term, genreId: tabs[index].genreId)
                }

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                } else {
                    AppListView(
                        viewModel: viewModel,
                        apps: $viewModel.apps,
                        selectedIndex: $selectedIndex,
                        memoText: $memoText,
                        isShowingMemoEditor: $isShowingMemoEditor,
                        isShowingMemoOnDrag: $isShowingMemoOnDrag,
                        selectedApp: $selectedApp,
                        selectedMemo: $selectedMemo,
                        isLoadingMore: viewModel.isLoadingMore,
                        onLoadMore: {
                            viewModel.loadMore(
                                term: tabs[selectedIndex].term,
                                genreId: tabs[selectedIndex].genreId
                            )
                        }
                    )
                }
            }

            if isShowingMemoEditor {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        memoText = ""
                        selectedMemo = nil
                        isShowingMemoEditor = false
                        isShowingMemoOnDrag = false
                    }

                MemoEditorView(text: $memoText, isShowingMemoOnDrag: $isShowingMemoOnDrag, appName: selectedMemo?.name, onSave: {
                    viewModel.saveMemo(memoText, for: selectedMemo?.id ?? 0)
                    
                    memoText = ""
                    selectedMemo = nil
                    isShowingMemoEditor = false
                    isShowingMemoOnDrag = false
                }) {
                    memoText = ""
                    selectedMemo = nil
                    isShowingMemoEditor = false
                    isShowingMemoOnDrag = false
                }
                .opacity(isShowingMemoOnDrag ? 0 : 1)
                .transition(.scale)
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

