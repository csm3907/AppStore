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

    public init(tabs: [Tab], selection: Binding<Tab>, title: @escaping (Tab) -> String) {
        self.tabs = tabs
        self._selection = selection
        self.title = title
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 16) {
                    ForEach(tabs) { tab in
                        Button {
                            withAnimation(.easeInOut) {
                                selection = tab
                                proxy.scrollTo(tab.id, anchor: .center)
                            }
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
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .onAppear {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(selection.id, anchor: .center)
                    }
                }
                .onChange(of: selection) { newValue in
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(newValue.id, anchor: .center)
                    }
                }
            }
        }
    }
}

