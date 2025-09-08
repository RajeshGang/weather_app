//
//  Model.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/7/25.
//
import Foundation

struct WeatherResponse: Codable {
    let current: Current
    let daily: Daily

    struct Current: Codable {
        let temperature_2m: Double
        let wind_speed_10m: Double
        let relative_humidity_2m: Double
        let weather_code: Int
    }

    struct Daily: Codable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let precipitation_sum: [Double]
    }
}

enum AppError: LocalizedError {
    case network, parsing, locationDenied, unknown
    var errorDescription: String? {
        switch self {
        case .network: return "Network error."
        case .parsing: return "Could not parse weather data."
        case .locationDenied: return "Location permission denied."
        case .unknown: return "Something went wrong."
        }
    }
}

