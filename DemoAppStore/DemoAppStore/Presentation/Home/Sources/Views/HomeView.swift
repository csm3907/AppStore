import SwiftUI
import UIKit
import Core

// MARK: - HomeView

//public struct HomeView: View {
//
//    @State private var selectedIndex: Int = 0
//    private let tabs = HomeTab.allCases
//
//    public init() {}
//
//    public var body: some View {
//        VStack(spacing: 0) {
//            InfiniteTabMenuView(tabs: tabs, selectedIndex: $selectedIndex)
//                .padding(.top, 8)
//
//            TabContentView(title: tabs[selectedIndex].description, count: tabs.count, selectedIndex: $selectedIndex)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
//}

private enum HomeTab: String, CaseIterable, CustomStringConvertible, Identifiable {
    case today = "투데이"
    case games = "게임"
    case apps = "앱"
    case arcade = "아케이드"
    case search = "검색"

    var id: Self { self }
    var description: String { rawValue }
}


public struct HomeView: View {

    @State private var selectedIndex: Int = 0
    private let tabs = HomeTab.allCases

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            InfiniteTabMenuView(tabs: tabs, selectedIndex: $selectedIndex)

            MainView(selectedIndex: $selectedIndex)
        }
    }
}

struct MainView: View {

    // MARK: - Variables
    @Binding var selectedIndex: Int
    @State private var showPreviousCard = false

    private let tabs = HomeTab.allCases
    private let colors: [Color] = [.red, .green, .blue, .orange, .purple]

    // MARK: - Views
    var body: some View {
        ZStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                if index == selectedIndex {
                    RoundedRectangle(cornerRadius: 24)
                        .foregroundStyle(colors[index % colors.count])
                        .overlay {
                            Text(tabs[index].description)
                                .font(.system(size: 78, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: showPreviousCard ? .leading : .trailing),
                                removal: .move(edge: showPreviousCard ? .trailing : .leading)
                            )
                        )
                        .frame(height: 240)
                        .padding(24)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 100

                    if value.translation.width < -threshold {
                        // left swipe
                        showPreviousCard = false

                        withAnimation(.snappy) {
                            selectedIndex = (selectedIndex + 1) % tabs.count
                        }

                    } else if value.translation.width > threshold {
                        // right swipe
                        showPreviousCard = true

                        withAnimation(.snappy) {
                            selectedIndex = (selectedIndex - 1 + tabs.count) % tabs.count
                        }
                    }
                }
        )
    }
}


