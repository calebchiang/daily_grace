//
//  MainTabView.swift
//  bible_ios
//
//  Created by Caleb Chiang on 2026-01-29.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(1)

            StudyView()
                   .tabItem {
                       Image(systemName: "book")
                   }
                   .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
                .tag(3)
        }
        .font(.custom("Palatino", size: 13))
        .onChange(of: selectedTab) {
            haptic.impactOccurred()
        }
    }
}

