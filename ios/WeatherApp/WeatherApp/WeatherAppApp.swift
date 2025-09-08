//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//

import SwiftUI

@main
struct WeatherAppApp: App {
    @StateObject private var locationManager = LocationManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
        }
    }
}
