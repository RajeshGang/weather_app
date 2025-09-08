//
//  RootView.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star.fill") }
        }
    }
}
