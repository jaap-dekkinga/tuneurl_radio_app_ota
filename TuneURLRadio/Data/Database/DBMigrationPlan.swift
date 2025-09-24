import Foundation
import SwiftData

enum DBMigrationPlan: SchemaMigrationPlan {
    
    static var schemas: [any VersionedSchema.Type] {
        [DBSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []// [migrateV1toV2]
    }
    
//    static let migrateV1toV2 = MigrationStage.custom(
//        fromVersion: DBSchemaV1.self,
//        toVersion: DBSchemaV2.self,
//        willMigrate: { context in
//            // remove duplicates then save
//        }, didMigrate: nil
//    )
}
