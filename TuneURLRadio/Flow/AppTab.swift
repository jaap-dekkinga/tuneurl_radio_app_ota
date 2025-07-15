import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
        case stations
        case saved
        case settings
        
        var id: Self { self }
        
        var title: LocalizedStringKey {
            switch self {
                case .stations: return "Stations"
                case .saved: return "Saved URLs"
                case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
                case .stations: return "radio"
                case .saved: return "bookmark"
                case .settings: return "gear"
            }
        }
    }
