import Foundation
import CoreData

extension TaskEntity {

    @nonobjc
    class func fetchRequest()
        -> NSFetchRequest<TaskEntity> {

        NSFetchRequest<TaskEntity>(
            entityName: "TaskEntity"
        )
    }

    @NSManaged var id: UUID?
    @NSManaged var remoteID: Int64
    @NSManaged var title: String?
    @NSManaged var detailsText: String?
    @NSManaged var createdAt: Date?
    @NSManaged var isCompleted: Bool
}
