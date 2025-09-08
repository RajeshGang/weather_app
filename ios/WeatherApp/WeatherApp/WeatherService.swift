//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//
import Foundation

final class WeatherService {
    func fetch(lat: Double, lon: Double) async throws -> WeatherResponse {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(lat)),
            .init(name: "longitude", value: String(lon)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum"),
            .init(name: "timezone", value: "auto")
        ]
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw AppError.network }
        do { return try JSONDecoder().decode(WeatherResponse.self, from: data) }
        catch { throw AppError.parsing }
    }
}

