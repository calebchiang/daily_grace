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
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .font(.custom("Palatino", size: 13)) 
        .onChange(of: selectedTab) {
            haptic.impactOccurred()
        }
    }
}

