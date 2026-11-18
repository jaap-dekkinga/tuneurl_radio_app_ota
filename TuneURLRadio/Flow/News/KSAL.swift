import Foundation

/// Fixed KSAL content: WordPress categories, community links and team sites.
/// The URLs come from the ksal.com menus (read 2026-11-18).
enum KSAL {

    static let site = URL(string: "https://www.ksal.com")!
    static let postsAPI = URL(string: "https://www.ksal.com/wp-json/wp/v2/posts")!

    /// The station that "Hear more" in an article plays (id in stations.json).
    static let newsStationID = 3

    // MARK: - News categories (WordPress category ids)

    struct Category: Identifiable, Hashable {
        let id: String
        let title: String
        /// nil = all posts
        let wordpressID: Int?
    }

    static let topStories = Category(id: "top", title: "Top Stories", wordpressID: nil)
    static let kansasNews = Category(id: "kansas", title: "Kansas", wordpressID: 9)
    static let sportsNews = Category(id: "sports", title: "Sports", wordpressID: 15100)
    static let farmingNews = Category(id: "farm", title: "Farm", wordpressID: 20443)
    static let commentary = Category(id: "commentary", title: "Commentary", wordpressID: 15974)

    static let homeCategories: [Category] = [topStories, kansasNews, sportsNews, farmingNews, commentary]

    // MARK: - Links

    struct Link: Identifiable, Hashable {
        let id: String
        let title: String
        let systemImage: String
        let url: URL
    }

    private static func link(_ id: String, _ title: String, _ systemImage: String, _ url: String) -> Link {
        Link(id: id, title: title, systemImage: systemImage, url: URL(string: url)!)
    }

    // Weather
    static let forecast = link("forecast", "Forecast", "calendar", "https://www.ksal.com/forecast/")
    static let radar = link("radar", "Radar", "dot.radiowaves.left.and.right", "https://radar.weather.gov/radar.php?product=NCR&rid=ICT&loop=yes")
    static let roads = link("roads", "Roads", "road.lanes", "https://kandrive.gov/@-99.86957,38.77164,7?show=roadReports,constructionReports,trafficSpeeds,winterDriving,weatherRadar")
    static let closings = link("closings", "Closings & Delays", "exclamationmark.triangle", "https://www.ksal.com/closings/")

    // Community
    static let communityLinks: [Link] = [
        link("obituaries", "Obituaries", "heart", "https://www.ksal.com/obituaries/"),
        link("auctions", "Auctions", "hammer", "https://www.ksal.com/auctions/"),
        link("calendar", "Calendar", "calendar", "https://www.ksal.com/calendar/"),
        link("jobs", "Jobs", "briefcase", "https://kansasjobslink.com/"),
        link("bookings", "Bookings", "shield", "https://www.ksal.com/sheriff-bookings/"),
        link("inspections", "Inspections", "fork.knife", "https://www.ksal.com/restaurant-inspections/"),
        link("graduations", "Graduations", "graduationcap", "https://www.ksal.com/graduation-announcements/"),
        link("education", "Education", "book", "https://www.ksal.com/education/"),
        link("wanted", "Most Wanted", "person.crop.rectangle", "https://www.ksal.com/most-wanted/"),
        link("lineup", "KSAL Lineup", "list.bullet.rectangle", "https://www.ksal.com/ksal-lineup/"),
        link("archives", "News Archive", "archivebox", "https://www.ksal.com/news/"),
        link("farming", "Ag News", "leaf", "https://www.ksal.com/farming-news/"),
    ]

    // Sports and audio
    static let scoreboard = link("scoreboard", "Scoreboard & Schedules", "sportscourt", "https://www.ksal.com/broadcast-schedule-results/")
    static let sportsAudio = link("sportsAudio", "Sports Audio", "waveform", "https://www.ksal.com/sports-audio/")
    static let pastShows = link("pastShows", "Past Shows", "play.square.stack", "https://soundcloud.com/oddittenger")
    static let lineup = link("lineupAudio", "KSAL Lineup", "list.bullet.rectangle", "https://www.ksal.com/ksal-lineup/")

    struct Team: Identifiable, Hashable {
        let id: String
        let short: String
        let name: String
        let url: URL
    }

    static let teams: [Team] = [
        Team(id: "kstate", short: "KSU", name: "Wildcats", url: URL(string: "https://www.kstatesports.com/")!),
        Team(id: "ku", short: "KU", name: "Jayhawks", url: URL(string: "https://kuathletics.com/")!),
        Team(id: "chiefs", short: "KC", name: "Chiefs", url: URL(string: "https://www.chiefs.com/")!),
        Team(id: "royals", short: "KCR", name: "Royals", url: URL(string: "https://www.mlb.com/royals")!),
        Team(id: "shockers", short: "WSU", name: "Shockers", url: URL(string: "https://goshockers.com/")!),
    ]

    // Salina, for the NWS forecast
    static let latitude = 38.8403
    static let longitude = -97.6114
}

/// A web page shown in-app (SFSafariViewController).
struct InAppWebPage: Identifiable, Hashable {
    let url: URL
    var id: URL { url }
}
