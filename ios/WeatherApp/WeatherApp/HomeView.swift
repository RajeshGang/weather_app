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
    @State private var response: WeatherResponse?
    @State private var isLoading = false
    @State private var err: AppError?
    let svc = WeatherService()

    var body: some View {
        Group {
            if let resp = response {
                ScrollView {
                    VStack(spacing: 16) {
                        CurrentCard(current: resp.current)
                        DailyList(daily: resp.daily)
                    }
                    .padding()
                }
                .refreshable { await load() }
            } else if isLoading {
                ProgressView("Loading weather…")
            } else {
                VStack(spacing: 10) {
                    Text("Allow location to see local weather")
                    Button("Request Location") { location.request() }
                }
                .padding()
            }
        }
        .navigationTitle("Weather")
        .task { await load() }
        .alert(err?.localizedDescription ?? "", isPresented: .constant(err != nil)) {
            Button("OK") { err = nil }
        }
    }

    func load() async {
        guard let c = location.coordinate else { return }
        isLoading = true
        do { response = try await svc.fetch(lat: c.latitude, lon: c.longitude) }
        catch let e as AppError { err = e }
        catch { err = .unknown }
        isLoading = false
    }
}

private struct CurrentCard: View {
    let current: WeatherResponse.Current
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now").font(.headline)
            HStack {
                Image(systemName: "thermometer.sun")
                Text("\(Int(current.temperature_2m))°C")
                Spacer()
                Image(systemName: "wind")
                Text("\(Int(current.wind_speed_10m)) m/s")
            }
            HStack {
                Image(systemName: "humidity")
                Text("\(Int(current.relative_humidity_2m))% RH")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }
}

private struct DailyList: View {
    let daily: WeatherResponse.Daily
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Forecast").font(.headline)
            ForEach(daily.time.indices, id: \.self) { i in
                HStack {
                    Text(daily.time[i])
                    Spacer()
                    Text("\(Int(daily.temperature_2m_min[i]))° / \(Int(daily.temperature_2m_max[i]))°")
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }
}

