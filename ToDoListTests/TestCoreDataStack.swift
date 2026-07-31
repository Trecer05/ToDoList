import CoreData
import Foundation

@testable import ToDoList

enum TestCoreDataStackError:
    Error {

    case persistentStoreDidNotLoad
    case persistentStoreLoadFailed(Error)
}

private final class StoreLoadResult:
    @unchecked Sendable {

    private let lock = NSLock()
    private var storedError: Error?

    func store(error: Error?) {
        lock.lock()
        storedError = error
        lock.unlock()
    }

    func error() -> Error? {
        lock.lock()
        defer { lock.unlock() }
        return storedError
    }
}

enum TestCoreDataStack {

    static func makeContainer()
        throws -> NSPersistentContainer {

        let container =
            NSPersistentContainer(
                name: "ToDoList",
                managedObjectModel:
                    makeManagedObjectModel()
            )

        let description =
            NSPersistentStoreDescription()

        description.type =
            NSInMemoryStoreType

        description.shouldAddStoreAsynchronously =
            false

        container.persistentStoreDescriptions =
            [description]

        let loadResult = StoreLoadResult()

        container.loadPersistentStores {
            _,
            error in

            loadResult.store(error: error)
        }

        if let error = loadResult.error() {
            throw TestCoreDataStackError
                .persistentStoreLoadFailed(error)
        }

        guard
            !container
                .persistentStoreCoordinator
                .persistentStores
                .isEmpty
        else {
            throw TestCoreDataStackError
                .persistentStoreDidNotLoad
        }

        container.viewContext.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        container.viewContext
            .automaticallyMergesChangesFromParent =
                true

        return container
    }

    private static func makeManagedObjectModel()
        -> NSManagedObjectModel {

        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()

        entity.name = "TaskEntity"

        entity.managedObjectClassName =
            NSStringFromClass(
                TaskEntity.self
            )

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .UUIDAttributeType
        id.isOptional = true

        let remoteID =
            NSAttributeDescription()

        remoteID.name = "remoteID"

        remoteID.attributeType =
            .integer64AttributeType

        remoteID.isOptional = true
        remoteID.defaultValue = 0

        let title =
            NSAttributeDescription()

        title.name = "title"

        title.attributeType =
            .stringAttributeType

        title.isOptional = true

        let details =
            NSAttributeDescription()

        details.name = "detailsText"

        details.attributeType =
            .stringAttributeType

        details.isOptional = true

        let createdAt =
            NSAttributeDescription()

        createdAt.name = "createdAt"

        createdAt.attributeType =
            .dateAttributeType

        createdAt.isOptional = true

        let isCompleted =
            NSAttributeDescription()

        isCompleted.name = "isCompleted"

        isCompleted.attributeType =
            .booleanAttributeType

        isCompleted.isOptional = true
        isCompleted.defaultValue = false

        entity.properties = [
            id,
            remoteID,
            title,
            details,
            createdAt,
            isCompleted
        ]

        entity.uniquenessConstraints = [
            ["id"]
        ]

        model.entities = [entity]

        return model
    }
}

@MainActor
enum RepositoryAwaiter {

    static func fetch(
        from repository: TaskRepository,
        matching query: String = ""
    ) async -> Result<
        [TaskItem],
        TaskRepositoryError
    > {
        await withCheckedContinuation {
            continuation in

            repository.fetchTasks(
                matching: query
            ) { result in
                continuation.resume(
                    returning: result
                )
            }
        }
    }

    static func create(
        in repository: TaskRepository,
        title: String,
        details: String = ""
    ) async -> Result<
        TaskItem,
        TaskRepositoryError
    > {
        await withCheckedContinuation {
            continuation in

            repository.createTask(
                title: title,
                details: details
            ) { result in
                continuation.resume(
                    returning: result
                )
            }
        }
    }

    static func update(
        in repository: TaskRepository,
        id: UUID,
        title: String,
        details: String
    ) async -> Result<
        TaskItem,
        TaskRepositoryError
    > {
        await withCheckedContinuation {
            continuation in

            repository.updateTask(
                id: id,
                title: title,
                details: details
            ) { result in
                continuation.resume(
                    returning: result
                )
            }
        }
    }

    static func setCompletion(
        in repository: TaskRepository,
        id: UUID,
        isCompleted: Bool
    ) async -> Result<
        TaskItem,
        TaskRepositoryError
    > {
        await withCheckedContinuation {
            continuation in

            repository.setTaskCompletion(
                id: id,
                isCompleted: isCompleted
            ) { result in
                continuation.resume(
                    returning: result
                )
            }
        }
    }

    static func delete(
        from repository: TaskRepository,
        id: UUID
    ) async -> Result<
        Void,
        TaskRepositoryError
    > {
        await withCheckedContinuation {
            continuation in

            repository.deleteTask(
                id: id
            ) { result in
                continuation.resume(
                    returning: result
                )
            }
        }
    }
}
