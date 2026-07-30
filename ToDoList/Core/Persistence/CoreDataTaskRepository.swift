import Foundation
import CoreData

nonisolated final class CoreDataTaskRepository:
    TaskRepository,
    @unchecked Sendable {

    private enum Limits {
        static let maximumTitleLength = 200
        static let maximumDetailsLength = 4_000
        static let maximumSearchLength = 200
    }

    private let persistentContainer:
        NSPersistentContainer

    private let operationQueue: OperationQueue

    init(
        persistentContainer: NSPersistentContainer
    ) {
        self.persistentContainer =
            persistentContainer

        let operationQueue = OperationQueue()

        operationQueue.name =
            "com.sergeytretyakov.ToDoList.repository"

        operationQueue.qualityOfService =
            .userInitiated

        // Последовательная очередь защищает
        // от конфликтующих одновременных записей.
        operationQueue.maxConcurrentOperationCount = 1

        self.operationQueue = operationQueue
    }

    func fetchTasks(
        matching query: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    [TaskItem],
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        enqueue(
            { context in
                let request:
                    NSFetchRequest<TaskEntity> =
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
                request.returnsObjectsAsFaults = false

                let normalizedQuery =
                    query.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                let safeQuery = String(
                    normalizedQuery.prefix(
                        Limits.maximumSearchLength
                    )
                )

                if !safeQuery.isEmpty {
                    request.predicate = NSPredicate(
                        format: """
                        title CONTAINS[cd] %@ OR \
                        detailsText CONTAINS[cd] %@
                        """,
                        safeQuery,
                        safeQuery
                    )
                }

                let entities =
                    try context.fetch(request)

                return entities.compactMap {
                    TaskEntityMapper.makeTask(
                        from: $0
                    )
                }
            },
            completion: completion
        )
    }

    func createTask(
        title: String,
        details: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        enqueue(
            { context in
                let validated =
                    try Self.validate(
                        title: title,
                        details: details
                    )

                let task = TaskItem(
                    remoteID: nil,
                    title: validated.title,
                    details: validated.details,
                    createdAt: Date(),
                    isCompleted: false
                )

                let entity = TaskEntity(
                    context: context
                )

                TaskEntityMapper.apply(
                    task,
                    to: entity
                )

                try Self.save(context)

                return task
            },
            completion: completion
        )
    }

    func updateTask(
        id: UUID,
        title: String,
        details: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        enqueue(
            { context in
                let validated =
                    try Self.validate(
                        title: title,
                        details: details
                    )

                guard
                    let entity =
                        try Self.fetchEntity(
                            id: id,
                            in: context
                        )
                else {
                    throw TaskRepositoryError
                        .taskNotFound
                }

                entity.title = validated.title
                entity.detailsText =
                    validated.details

                try Self.save(context)

                guard
                    let task =
                        TaskEntityMapper.makeTask(
                            from: entity
                        )
                else {
                    throw TaskRepositoryError
                        .corruptedTask
                }

                return task
            },
            completion: completion
        )
    }

    func deleteTask(
        id: UUID,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    Void,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        enqueue(
            { context in
                guard
                    let entity =
                        try Self.fetchEntity(
                            id: id,
                            in: context
                        )
                else {
                    throw TaskRepositoryError
                        .taskNotFound
                }

                context.delete(entity)

                try Self.save(context)

                return ()
            },
            completion: completion
        )
    }

    func toggleTask(
        id: UUID,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        enqueue(
            { context in
                guard
                    let entity =
                        try Self.fetchEntity(
                            id: id,
                            in: context
                        )
                else {
                    throw TaskRepositoryError
                        .taskNotFound
                }

                entity.isCompleted.toggle()

                try Self.save(context)

                guard
                    let task =
                        TaskEntityMapper.makeTask(
                            from: entity
                        )
                else {
                    throw TaskRepositoryError
                        .corruptedTask
                }

                return task
            },
            completion: completion
        )
    }

    private func enqueue<Value: Sendable>(
        _ work:
            @escaping @Sendable (
                NSManagedObjectContext
            ) throws -> Value,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    Value,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        operationQueue.addOperation {
            [weak self] in

            guard let self else { return }

            let context =
                self.makeBackgroundContext()

            let result:
                Result<
                    Value,
                    TaskRepositoryError
                >

            do {
                let value =
                    try context.performAndWait {
                        try work(context)
                    }

                result = .success(value)
            } catch let error
                as TaskRepositoryError {

                context.performAndWait {
                    if context.hasChanges {
                        context.rollback()
                    }
                }

                result = .failure(error)
            } catch {
                context.performAndWait {
                    if context.hasChanges {
                        context.rollback()
                    }
                }

                result = .failure(
                    .persistence(
                        error.localizedDescription
                    )
                )
            }

            self.deliver(
                result,
                to: completion
            )
        }
    }

    private func makeBackgroundContext()
        -> NSManagedObjectContext {

        let context =
            persistentContainer
                .newBackgroundContext()

        context.name = "TaskRepositoryContext"

        context.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        context.undoManager = nil

        return context
    }

    private static func fetchEntity(
        id: UUID,
        in context: NSManagedObjectContext
    ) throws -> TaskEntity? {
        let request:
            NSFetchRequest<TaskEntity> =
                TaskEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            id as NSUUID
        )

        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    private static func validate(
        title: String,
        details: String
    ) throws -> (
        title: String,
        details: String
    ) {
        let normalizedTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let normalizedDetails =
            details.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalizedTitle.isEmpty else {
            throw TaskRepositoryError.invalidTitle
        }

        guard
            normalizedTitle.count <=
                Limits.maximumTitleLength
        else {
            throw TaskRepositoryError
                .titleTooLong(
                    maximum:
                        Limits.maximumTitleLength
                )
        }

        guard
            normalizedDetails.count <=
                Limits.maximumDetailsLength
        else {
            throw TaskRepositoryError
                .detailsTooLong(
                    maximum:
                        Limits.maximumDetailsLength
                )
        }

        return (
            title: normalizedTitle,
            details: normalizedDetails
        )
    }

    private static func save(
        _ context: NSManagedObjectContext
    ) throws {
        guard context.hasChanges else {
            return
        }

        try context.save()
    }

    private func deliver<Value: Sendable>(
        _ result:
            Result<
                Value,
                TaskRepositoryError
            >,
        to completion:
            @escaping @MainActor @Sendable (
                Result<
                    Value,
                    TaskRepositoryError
                >
            ) -> Void
    ) {
        Task { @MainActor in
            completion(result)
        }
    }
}
