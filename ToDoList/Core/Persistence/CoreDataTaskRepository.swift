import Foundation
import CoreData

final class CoreDataTaskRepository: TaskRepository {

    private let context: NSManagedObjectContext

    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }

    func fetchTasks(
        matching query: String
    ) throws -> [TaskItem] {
        let request: NSFetchRequest<TaskEntity> =
            TaskEntity.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(
                key: "createdAt",
                ascending: false
            ),
            NSSortDescriptor(
                key: "remoteID",
                ascending: true
            )
        ]

        request.fetchBatchSize = 50

        let normalizedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !normalizedQuery.isEmpty {
            request.predicate = NSPredicate(
                format: """
                title CONTAINS[cd] %@ OR \
                detailsText CONTAINS[cd] %@
                """,
                normalizedQuery,
                normalizedQuery
            )
        }

        let entities = try context.fetch(request)

        return entities.compactMap {
            TaskEntityMapper.makeTask(from: $0)
        }
    }

    func toggleTask(
        id: UUID
    ) throws {
        let request: NSFetchRequest<TaskEntity> =
            TaskEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            id as NSUUID
        )

        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            return
        }

        entity.isCompleted.toggle()

        try saveContextIfNeeded()
    }

    private func saveContextIfNeeded() throws {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
