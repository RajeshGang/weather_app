//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//

import SwiftUI

@main
struct WeatherAppApp: App {
    // This wires AppDelegate so didFinishLaunching runs
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var locationManager = LocationManager()
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var session = AppSession()

    init() {}

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(favorites)
                .environmentObject(session)
        }
    }
}
