import Foundation

/// Current conditions for Salina from the National Weather Service (api.weather.gov, no key).
@MainActor
@Observable
final class WeatherStore {

    static let shared = WeatherStore()

    struct Conditions: Equatable {
        let temperature: Int
        let unit: String
        let summary: String
    }

    private(set) var conditions: Conditions?
    private(set) var isLoading = false

    @ObservationIgnored private var hourlyURL: URL?
    @ObservationIgnored private var lastUpdate: Date?

    func refreshIfNeeded() async {
        if let lastUpdate, Date.now.timeIntervalSince(lastUpdate) < 15 * 60 { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if hourlyURL == nil {
                let points = URL(string: "https://api.weather.gov/points/\(KSAL.latitude),\(KSAL.longitude)")!
                let result: PointsResponse = try await fetch(points)
                hourlyURL = result.properties.forecastHourly
            }
            guard let hourlyURL else { return }
            let forecast: ForecastResponse = try await fetch(hourlyURL)
            if let now = forecast.properties.periods.first {
                conditions = Conditions(
                    temperature: now.temperature,
                    unit: now.temperatureUnit,
                    summary: now.shortForecast
                )
                lastUpdate = .now
            }
        } catch {
            // Keep the last value; the card shows a fallback when there is none.
        }
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        // NWS asks every client to identify itself.
        request.setValue("TuneURLRadio iOS app (ksal.com news)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private struct PointsResponse: Decodable {
        struct Properties: Decodable { let forecastHourly: URL }
        let properties: Properties
    }

    private struct ForecastResponse: Decodable {
        struct Period: Decodable {
            let temperature: Int
            let temperatureUnit: String
            let shortForecast: String
        }
        struct Properties: Decodable { let periods: [Period] }
        let properties: Properties
    }
}
