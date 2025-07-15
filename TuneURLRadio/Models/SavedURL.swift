import Foundation
import SwiftData

@Model
final class SavedURL {
    var url: String
    
    init(url: String) {
        self.url = url
    }
}
