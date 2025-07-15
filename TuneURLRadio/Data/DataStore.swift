import Foundation

@Observable
class DataStore {
    
    static let shared = DataStore()
    
    var stations: [Station] = []
    
    init() {
        loadStations()
    }
    
    private func loadStations() {
        let fileURL = Bundle.main.url(forResource: "stations", withExtension: "json")
        guard let fileURL else {
            print("Failed to find stations.json in bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            stations = try decoder.decode([Station].self, from: data)
        } catch {
            print("Error loading stations: \(error)")
        }
    }
}
