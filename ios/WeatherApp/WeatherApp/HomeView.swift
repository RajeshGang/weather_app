//
//  HomeView.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//
import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var location: LocationManager
    @EnvironmentObject var session: AppSession      // ← NEW
    @AppStorage("useFahrenheit") private var useFahrenheit = false
    @AppStorage("forceNightMode") private var forceNightMode = false

    @State private var response: WeatherResponse?
    @State private var isLoading = false
    @State private var isRequestingLocation = false
    @State private var err: AppError?
    @State private var lastFetchedCoord: CLLocationCoordinate2D?
    let svc = WeatherService()

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackground(isNight: isNight)
                content
            }
            .navigationTitle("Weather")
            .toolbar {
                // Left: show "Use My Location" only when a favorite is selected
                ToolbarItem(placement: .topBarLeading) {
                    if session.selectedPlace != nil {
                        Button {
                            session.selectedPlace = nil
                            Task { await load() }
                        } label: {
                            Label("Use My Location", systemImage: "location.fill")
                        }
                        .tint(.white)
                    }
                }
                // Right: refresh (uses either selected place OR current GPS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if session.selectedPlace == nil {
                            location.refresh() // only refresh GPS in location mode
                        }
                        Task { await load() }
                    } label: { Image(systemName: "arrow.clockwise.circle") }
                    .tint(.white)
                    .accessibilityLabel("Refresh")
                }
            }
        }
        .onAppear {
            if session.selectedPlace == nil, location.isAuthorized, location.coordinate == nil {
                location.refresh()
            }
        }
        // Re-fetch when GPS timestamp changes (current-location mode)
        .onChange(of: location.lastUpdated) { _ in Task { await load() } }
        // Re-fetch when a different favorite is chosen
        .onChange(of: session.selectedPlace?.id) { _ in Task { await load() } }
        .onChange(of: location.isAuthorized) { allowed in
            if allowed, session.selectedPlace == nil { location.refresh() }
        }
        .alert(err?.localizedDescription ?? "", isPresented: .constant(err != nil)) {
            Button("OK") { err = nil }
        }
    }

    // MARK: - Content

    @ViewBuilder private var content: some View {
        if let resp = response {
            ScrollView {
                VStack(spacing: 16) {
                    CityTextView(name: headerTitle)

                    if let c = activeCoordinates {
                        Text(String(format: "%.4f, %.4f", c.latitude, c.longitude))
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    if let t = lastUpdatedForHeader {
                        Text("Updated \(RelativeDateTimeFormatter().localizedString(for: t, relativeTo: Date()))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.bottom, 4)
                    }

                    MainWeatherStatusView(
                        symbol: mapCodeToSymbol(resp.current.weather_code),
                        tempText: formatTemp(resp.current.temperature_2m)
                    )

                    CurrentCard(current: resp.current, useFahrenheit: useFahrenheit)
                    DailyList(daily: resp.daily, useFahrenheit: useFahrenheit)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .refreshable { await load() }
        } else if isLoading {
            ProgressView("Loading weather…").tint(.white)
        } else {
            if session.selectedPlace != nil {
                VStack(spacing: 12) {
                    CityTextView(name: headerTitle)
                    ProgressView("Loading…").tint(.white)
                }.padding()
            } else {
                EmptyStateView(
                    isAuthorized: location.isAuthorized,
                    isRequesting: isRequestingLocation,
                    requestAction: {
                        isRequestingLocation = true
                        location.request()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            isRequestingLocation = false
                        }
                    },
                    openSettings: { location.openSettings() }
                )
            }
        }
    }

    // MARK: - Helpers

    /// Current source of coordinates: selected favorite OR GPS
    private var activeCoordinates: CLLocationCoordinate2D? {
        if let p = session.selectedPlace {
            return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
        }
        return location.coordinate
    }

    private var headerTitle: String {
        if let p = session.selectedPlace { return p.name }
        return location.placename.isEmpty ? "Current Location" : location.placename
    }

    private var lastUpdatedForHeader: Date? {
        if session.selectedPlace != nil { return Date() } // simple "just now"
        return location.lastUpdated
    }

    private var isNight: Bool {
        if forceNightMode { return true }
        let hour = Calendar.current.component(.hour, from: .now)
        return hour >= 18 || hour < 6
    }

    private func load() async {
        guard let c = activeCoordinates else { return }

        // Avoid jitter refetch when in location mode
        if session.selectedPlace == nil, let last = lastFetchedCoord,
           abs(last.latitude - c.latitude) < 0.0005,
           abs(last.longitude - c.longitude) < 0.0005 {
            return
        }
        lastFetchedCoord = c

        isLoading = true
        defer { isLoading = false }
        do {
            response = try await svc.fetch(lat: c.latitude, lon: c.longitude)
        } catch let e as AppError {
            err = e
        } catch {
            err = .unknown
        }
    }

    private func mapCodeToSymbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1,2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45,48: return "cloud.fog.fill"
        case 51,53,55,61,63,65: return "cloud.rain.fill"
        case 71,73,75,77: return "cloud.snow.fill"
        case 80,81,82: return "cloud.heavyrain.fill"
        case 95,96,99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    private func formatTemp(_ celsius: Double) -> String {
        let value = useFahrenheit ? (celsius * 9/5 + 32) : celsius
        return "\(Int(round(value)))°" + (useFahrenheit ? "F" : "C")
    }
}


private struct WeatherBackground: View {
    var isNight: Bool
    var body: some View {
        LinearGradient(
            colors: isNight ? [Color.black, Color.gray] : [Color.blue, Color.white],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct CityTextView: View {
    let name: String
    var body: some View {
        Text(name)
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(.white)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MainWeatherStatusView: View {
    let symbol: String
    let tempText: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.white)

            Text(tempText)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

private struct CurrentCard: View {
    let current: WeatherResponse.Current
    let useFahrenheit: Bool

    var tempText: String {
        let t = useFahrenheit ? (current.temperature_2m * 9/5 + 32) : current.temperature_2m
        return "\(Int(round(t)))°" + (useFahrenheit ? "F" : "C")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Now").font(.headline).foregroundStyle(.white)
            HStack {
                Label(tempText, systemImage: "thermometer.sun")
                Spacer()
                Label("\(Int(current.wind_speed_10m)) m/s", systemImage: "wind")
            }
            .foregroundStyle(.white.opacity(0.95))

            HStack {
                Label("\(Int(current.relative_humidity_2m))% RH", systemImage: "humidity")
            }
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8, y: 4)
    }
}

private struct DailyList: View {
    let daily: WeatherResponse.Daily
    let useFahrenheit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Forecast").font(.headline).foregroundStyle(.white)
            ForEach(daily.time.indices, id: \.self) { i in
                HStack {
                    Text(format(dateString: daily.time[i]))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(rangeText(minC: daily.temperature_2m_min[i], maxC: daily.temperature_2m_max[i]))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.vertical, 6)
                Divider().overlay(Color.white.opacity(0.15))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8, y: 4)
    }

    private func format(dateString: String) -> String {
        let inDF = DateFormatter()
        inDF.dateFormat = "yyyy-MM-dd"
        let outDF = DateFormatter()
        outDF.dateFormat = "EEE d MMM"
        if let d = inDF.date(from: dateString) {
            return outDF.string(from: d)
        }
        return dateString
    }

    private func toDisplay(_ c: Double) -> Int {
        useFahrenheit ? Int(round(c * 9/5 + 32)) : Int(round(c))
    }

    private func rangeText(minC: Double, maxC: Double) -> String {
        let unit = useFahrenheit ? "°F" : "°C"
        return "\(toDisplay(minC))\(unit) / \(toDisplay(maxC))\(unit)"
    }
}

// MARK: - Empty state (added)

private struct EmptyStateView: View {
    let isAuthorized: Bool
    let isRequesting: Bool
    let requestAction: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "location.circle")
                .resizable().scaledToFit().frame(width: 80, height: 80)
                .foregroundStyle(.white.opacity(0.9))
            Text(isAuthorized ? "Current Location" : "Location Needed")
                .font(.largeTitle).bold().foregroundStyle(.white)
            Text(isAuthorized
                 ? "Tap to refresh your location and load weather."
                 : "Enable location permission to show local weather.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 24)

            if isAuthorized {
                Button(isRequesting ? "Requesting…" : "Request Location") {
                    requestAction()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
            } else {
                HStack(spacing: 12) {
                    Button("Open Settings") { openSettings() }
                        .buttonStyle(.borderedProminent)
                    Button("Request Again") { requestAction() }
                        .buttonStyle(.bordered)
                }
            }
            Spacer()
        }
        .padding()
    }
}


