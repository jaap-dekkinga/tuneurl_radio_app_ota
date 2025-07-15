import Foundation

struct StationModel: Codable, Hashable, Identifiable {
    let name: String
    let streamURL: URL
    let imageURL: URL?
    let shortDescription: String
    let socialURL: URL?
    
    var id: String {
        streamURL.absoluteString
    }
}
