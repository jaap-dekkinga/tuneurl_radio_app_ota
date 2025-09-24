import Foundation
import SwiftData

typealias CurrentSchema = DBSchemaV1

class Persistance {
    
    static let shared = Persistance()
    
    @MainActor
    var container: ModelContainer = {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: DBMigrationPlan.self,
                configurations: modelConfiguration
            )
        } catch {
            do {
                let model = try ModelContainer(
                    for: Schema(),
                    configurations: [ModelConfiguration(
                        schema: Schema(),
                        isStoredInMemoryOnly: false
                    )]
                )
                if #available(iOS 18, *) {
                    try model.erase()
                } else {
                    model.deleteAllData()
                }
                
                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    @MainActor
    var previewContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CurrentSchema.self)
        
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
                engagement: Engagement(
                    id: 1,
                    type: "info",
                    name: "Artist Info",
                    description: "Learn more about the artist",
                    info: "Some info",
                    heardAt: Date.now,
                    sourceStationId: 1
                )
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    id: 2,
                    type: "poll",
                    name: "Poll",
                    description: "Vote for next song",
                    info: "Poll info",
                    heardAt: Date.now,
                    sourceStationId: 3
                )
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    id: 3,
                    type: "promotion",
                    name: "Promo",
                    description: "Get a discount",
                    info: "Promo code",
                    heardAt: Date.now,
                    sourceStationId: nil
                )
            )
            context.insert(mock)
            
            mock =  SavedEngagement(
                engagement: Engagement(
                    id: 4,
                    type: "info",
                    name: "Artist Info",
                    description: "Learn more about the artist",
                    info: "http://www.181.fm/",
                    heardAt: Date.now,
                    sourceStationId: 9
                )
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    id: 5,
                    type: "info",
                    name: "Concert Tickets",
                    description: "Buy tickets to upcoming shows",
                    info: "https://www.kissfm.ro/",
                    heardAt: Date.now,
                    sourceStationId: 12
                )
            )
            context.insert(mock)
            
            mock = SavedEngagement(
                engagement: Engagement(
                    id: 6,
                    type: "info",
                    name: "New Album",
                    description: "Listen to the new album now",
                    info: "https://www.goldradio.com/",
                    heardAt: Date.now,
                    sourceStationId: 13
                )
            )
            context.insert(mock)
            
            var historyMock = HistoryEngagement(
                engagement: Engagement(
                    id: 1,
                    type: "info",
                    name: "Artist Info",
                    description: "Learn more about the artist",
                    info: "http://www.181.fm/",
                    heardAt: Date.now,
                    sourceStationId: 9
                )
            )
            context.insert(historyMock)
            
            historyMock = HistoryEngagement(
                engagement: Engagement(
                    id: 2,
                    type: "info",
                    name: "Concert Tickets",
                    description: "Buy tickets to upcoming shows",
                    info: "https://www.kissfm.ro/",
                    heardAt: Date.now,
                    sourceStationId: 12
                )
            )
            context.insert(historyMock)
            
            historyMock = HistoryEngagement(
                engagement: Engagement(
                    id: 3,
                    type: "info",
                    name: "New Album",
                    description: "Listen to the new album now",
                    info: "https://www.goldradio.com/",
                    heardAt: Date.now,
                    sourceStationId: 13
                )
            )
            context.insert(historyMock)
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
