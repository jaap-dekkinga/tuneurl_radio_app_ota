import Foundation

struct Station: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let streamURL: URL
    let imageURL: URL?
    let shortDescription: String
    let socialURL: URL?
}
