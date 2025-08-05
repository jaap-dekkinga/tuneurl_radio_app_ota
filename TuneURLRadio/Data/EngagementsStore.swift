import Foundation
import SwiftData
import TuneURL

private let log = Log(label: "EngagementsStore")

@MainActor
@Observable
class EngagementsStore {
    
    static let shared = EngagementsStore()
    
    private init() {}
    
    private var context: ModelContext { Persistance.shared.container.mainContext }
    private var settings: UserSettings { UserSettings.shared }
    
    // MARK: - User Saved Engagements
    @discardableResult
    func save(_ engagement: Engagement, stationId: Int? = nil) -> SavedEngagement {
        let newEntity = SavedEngagement(
            engagement: engagement,
            stationId: stationId
        )
        context.insert(newEntity)
        do {
            try context.save()
        } catch {
            log.write("Could not save engagement: \(error.localizedDescription)")
        }
        return newEntity
    }
    
    func delete(_ engagement: SavedEngagement) {
        context.delete(engagement)
        do {
            try context.save()
        } catch {
            log.write("Could not delete engagement: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Engagement History
    func saveToHistory(match: TuneURL.Match, stationId: Int? = nil) {
        guard settings.storeAllEngagementsHistory else { return }
        do {
            let newEntity = HistoryEngagement(match: match, stationId: stationId)
            context.insert(newEntity)
            try context.save()
        } catch {
            log.write(
                "Failed to save engagement to history: \(error.localizedDescription)",
                level: .error
            )
        }
    }
    
    func delete(_ engagement: HistoryEngagement) {
        context.delete(engagement)
        do {
            try context.save()
        } catch {
            log.write("Could not delete engagement from history: \(error.localizedDescription)")
        }
    }
    
    func clearHistory() {
        let fetchRequest = FetchDescriptor<HistoryEngagement>()
        do {
            let engagements = try context.fetch(fetchRequest)
            for engagement in engagements {
                context.delete(engagement)
            }
            try context.save()
        } catch {
            log.write("Could not clear history: \(error.localizedDescription)")
        }
    }
}
