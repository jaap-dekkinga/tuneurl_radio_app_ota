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
            case .news: "News"
            case .stations: "Stations"
            case .saved: "Saved Turls"
            case .turls: "Turls"
            case .settings: "Settings"
        }
    }
    
    var icon: String {
        switch self {
            case .news: "newspaper"
            case .stations: "radio"
            case .saved: "bookmark"
            case .turls: "calendar.day.timeline.left"
            case .settings: "gear"
        }
    }
}

