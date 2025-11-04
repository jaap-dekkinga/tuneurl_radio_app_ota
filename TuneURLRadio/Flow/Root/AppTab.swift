import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case news
    case stations
    case saved
    case turls
    case settings
    
    var id: Self { self }
    
    var title: LocalizedStringKey {
      switch self {
        case .news: return "News"
        case .stations: return "Stations"
        case .saved: return "Saved Turls"
        case .turls: return "Turls"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
            case .news: return "newspaper"
            case .stations: return "radio"
            case .saved: return "bookmark"
            case .turls: return "calendar.day.timeline.left"
            case .settings: return "gear"
        }
    }
}

