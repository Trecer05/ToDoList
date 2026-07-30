import Foundation
import CoreData

nonisolated enum InitialTaskLoadError:
    LocalizedError,
    Sendable {

    case api(TaskAPIError)
    case emptyResponse
    case persistence(String)

    var errorDescription: String? {
        switch self {
        case .api(let error):
            return error.localizedDescription

        case .emptyResponse:
            return "Сервер не вернул ни одной задачи"

        case .persistence(let description):
            return "Не удалось сохранить задачи: \(description)"
        }
    }
}

nonisolated protocol InitialTaskLoading: AnyObject {

    func loadIfNeeded(
        completion: @escaping @MainActor @Sendable (
            Result<Int, InitialTaskLoadError>
        ) -> Void
    )
}

nonisolated final class InitialTaskLoader:
    InitialTaskLoading,
    @unchecked Sendable {

    private enum Constants {
        static let importCompletedKey =
            "didCompleteInitialTaskImport.v1"
    }

    private let apiClient: TaskAPIClient
    private let persistentContainer: NSPersistentContainer
    private let userDefaults: UserDefaults
    private let operationQueue: OperationQueue

    init(
        apiClient: TaskAPIClient,
        persistentContainer: NSPersistentContainer,
        userDefaults: UserDefaults = .standard
    ) {
        self.apiClient = apiClient
        self.persistentContainer = persistentContainer
        self.userDefaults = userDefaults

        let operationQueue = OperationQueue()
        operationQueue.name =
            "com.sergeytretyakov.ToDoList.initial-import"
        operationQueue.qualityOfService = .utility
        operationQueue.maxConcurrentOperationCount = 1

        self.operationQueue = operationQueue
    }

    func loadIfNeeded(
        completion: @escaping @MainActor @Sendable (
            Result<Int, InitialTaskLoadError>
        ) -> Void
    ) {
        guard
            !userDefaults.bool(
                forKey: Constants.importCompletedKey
            )
        else {
            deliver(
                .success(0),
                to: completion
            )
            return
        }

        apiClient.fetchTodos { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.deliver(
                    .failure(.api(error)),
                    to: completion
                )

            case .success(let todos):
                guard !todos.isEmpty else {
                    self.deliver(
                        .failure(.emptyResponse),
                        to: completion
                    )
                    return
                }

                self.operationQueue.addOperation {
                    [weak self] in

                    guard let self else { return }

                    do {
                        let importedCount =
                            try self.importTodos(todos)

                        self.userDefaults.set(
                            true,
                            forKey:
                                Constants.importCompletedKey
                        )

                        self.deliver(
                            .success(importedCount),
                            to: completion
                        )
                    } catch {
                        self.deliver(
                            .failure(
                                .persistence(
                                    error.localizedDescription
                                )
                            ),
                            to: completion
                        )
                    }
                }
            }
        }
    }

    private func importTodos(
        _ todos: [TodoDTO]
    ) throws -> Int {
        let context =
            persistentContainer.newBackgroundContext()

        context.name = "InitialTaskImportContext"
        context.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil

        var importedCount = 0
        var importError: Error?

        context.performAndWait {
            do {
                importedCount =
                    try self.insertMissingTodos(
                        todos,
                        into: context
                    )
            } catch {
                context.rollback()
                importError = error
            }
        }

        if let importError {
            throw importError
        }

        return importedCount
    }

    private func insertMissingTodos(
        _ todos: [TodoDTO],
        into context: NSManagedObjectContext
    ) throws -> Int {
        let request: NSFetchRequest<TaskEntity> =
            TaskEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "remoteID > 0"
        )
        request.fetchBatchSize = 100

        let existingEntities =
            try context.fetch(request)

        var existingRemoteIDs = Set(
            existingEntities.map(\.remoteID)
        )

        let importDate = Date()
        var insertedCount = 0

        for todo in todos {
            let normalizedTitle =
                todo.todo.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !normalizedTitle.isEmpty else {
                continue
            }

            guard
                let remoteID = Int64(
                    exactly: todo.id
                ),
                remoteID > 0
            else {
                continue
            }

            guard
                existingRemoteIDs
                    .insert(remoteID)
                    .inserted
            else {
                continue
            }

            let entity = TaskEntity(
                context: context
            )

            entity.id = UUID()
            entity.remoteID = remoteID
            entity.title = normalizedTitle
            entity.detailsText = ""

            entity.createdAt =
                importDate.addingTimeInterval(
                    -Double(insertedCount)
                )

            entity.isCompleted = todo.completed

            insertedCount += 1
        }

        if context.hasChanges {
            try context.save()
        }

        return insertedCount
    }

    private func deliver(
        _ result: Result<
            Int,
            InitialTaskLoadError
        >,
        to completion:
            @escaping @MainActor @Sendable (
                Result<
                    Int,
                    InitialTaskLoadError
                >
            ) -> Void
    ) {
        Task { @MainActor in
            completion(result)
        }
    }
}
