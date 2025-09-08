//
//  SettingsView.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/8/25.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("useFahrenheit") private var useFahrenheit = false
    @AppStorage("forceNightMode") private var forceNightMode = false

    var body: some View {
        Form {
            Section("Units") {
                Toggle("Use Fahrenheit (°F)", isOn: $useFahrenheit)
            }
            Section("Appearance") {
                Toggle("Force Night Mode (preview)", isOn: $forceNightMode)
                    .tint(.indigo)
                Text("Night mode will auto-switch after 6pm; this toggle lets you preview it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

