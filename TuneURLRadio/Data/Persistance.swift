import SwiftData

class Persistance {
    
    static let shared = Persistance()
    
    @MainActor
    var container: ModelContainer = {
        let schema = Schema([
            SavedEngagement.self,
            HistoryEngagement.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    var previewContainer: ModelContainer = {
        let schema = Schema([
            SavedEngagement.self,
            HistoryEngagement.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            let context = container.mainContext
            
            var mock = SavedEngagement(
                engagement: Engagement(type: "info", name: "Artist Info", description: "Learn more about the artist", info: "Some info"),
                stationId: 1
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(type: "poll", name: "Poll", description: "Vote for next song", info: "Poll info"),
                stationId: 3
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(type: "promotion", name: "Promo", description: "Get a discount", info: "Promo code"),
                stationId: nil
            )
            context.insert(mock)
            
            mock =  SavedEngagement(
                engagement: Engagement(
                    type: "info",
                    name: "Artist Info",
                    description: "Learn more about the artist",
                    info: "http://www.181.fm/"
                ),
                stationId: 9
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    type: "info",
                    name: "Concert Tickets",
                    description: "Buy tickets to upcoming shows",
                    info: "https://www.kissfm.ro/"
                ),
                stationId: 12
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    type: "info",
                    name: "New Album",
                    description: "Listen to the new album now",
                    info: "https://www.goldradio.com/"
                ),
                stationId: 13
            )
            context.insert(mock)
            
            
            var historyMock = HistoryEngagement(
                type: "info",
                name: "Artist Info",
                description: "Learn more about the artist",
                info: "http://www.181.fm/",
                stationId: 9
            )
            context.insert(historyMock)
            
            historyMock = HistoryEngagement(
                type: "info",
                name: "Concert Tickets",
                description: "Buy tickets to upcoming shows",
                info: "https://www.kissfm.ro/",
                stationId: 12
            )
            context.insert(historyMock)
            
            historyMock = HistoryEngagement(
                type: "info",
                name: "New Album",
                description: "Listen to the new album now",
                info: "https://www.goldradio.com/",
                stationId: 13
            )
            context.insert(historyMock)
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
