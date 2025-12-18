//
//  ContentView.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}
