import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case stations
    case saved
    case turls
    case settings
    
    var id: Self { self }
    
    var title: LocalizedStringKey {
        switch self {
            case .stations: "Stations"
            case .saved: "Saved URLs"
            case .turls: "Turls"
            case .settings: "Settings"
        }
    }
    
    var icon: String {
        switch self {
            case .stations: "radio"
            case .saved: "bookmark"
            case .turls: "calendar.day.timeline.left"
            case .settings: "gear"
        }
    }
}

