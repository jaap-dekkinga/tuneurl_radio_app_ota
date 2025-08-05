import Foundation

extension String {
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var nilIfEmpty: String? {
        return isEmpty ? nil : self
    }
}
