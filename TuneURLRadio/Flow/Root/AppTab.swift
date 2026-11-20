import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case home
    case sports
    case local
    case listen
    case turls

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .home: return "Home"
        case .sports: return "Sports"
        case .local: return "Local"
        case .listen: return "Listen"
        case .turls: return "Turls"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .sports: return "sportscourt"
        case .local: return "mappin.and.ellipse"
        case .listen: return "radio"
        case .turls: return "bookmark"
        }
    }
}
