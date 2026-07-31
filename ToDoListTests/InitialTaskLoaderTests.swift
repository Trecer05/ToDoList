import Foundation
import Testing

@testable import ToDoList

private enum InitialTaskLoaderTestError:
    Error {

    case userDefaultsUnavailable
}

nonisolated private final class TaskAPIClientSequenceMock:
    TaskAPIClient,
    @unchecked Sendable {

    private let lock = NSLock()

    private var results:
        [Result<[TodoDTO], TaskAPIError>]

    private var storedRequestCount = 0

    init(
        results:
            [Result<[TodoDTO], TaskAPIError>]
    ) {
        self.results = results
    }

    var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedRequestCount
    }

    func fetchTodos(
        completion: @escaping @Sendable (
            Result<[TodoDTO], TaskAPIError>
        ) -> Void
    ) {
        let result:
            Result<[TodoDTO], TaskAPIError>

        lock.lock()
        storedRequestCount += 1

        if results.isEmpty {
            result = .success([])
        } else {
            result = results.removeFirst()
        }

        lock.unlock()

        completion(result)
    }
}

@MainActor
@Suite("InitialTaskLoader")
struct InitialTaskLoaderTests {

    @Test(
        "Стартовые задачи импортируются один раз"
    )
    func initialTasksAreImportedOnlyOnce()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let defaultsName =
            "InitialTaskLoaderTests.\(UUID())"

        guard
            let userDefaults =
                UserDefaults(
                    suiteName: defaultsName
                )
        else {
            throw InitialTaskLoaderTestError
                .userDefaultsUnavailable
        }

        defer {
            userDefaults.removePersistentDomain(
                forName: defaultsName
            )
        }

        let todos = [
            TodoDTO(
                id: 1,
                todo: "Первая задача",
                completed: false,
                userID: 10
            ),
            TodoDTO(
                id: 2,
                todo: "Вторая задача",
                completed: true,
                userID: 10
            )
        ]

        let apiClient =
            TaskAPIClientSequenceMock(
                results: [.success(todos)]
            )

        let loader = InitialTaskLoader(
            apiClient: apiClient,
            persistentContainer: container,
            userDefaults: userDefaults
        )

        let firstCount = try await
            load(using: loader)
            .get()

        let secondCount = try await
            load(using: loader)
            .get()

        #expect(firstCount == 2)
        #expect(secondCount == 0)
        #expect(apiClient.requestCount == 1)

        let repository =
            CoreDataTaskRepository(
                persistentContainer:
                    container
            )

        let storedTasks = try await
            RepositoryAwaiter.fetch(
                from: repository
            )
            .get()

        #expect(storedTasks.count == 2)

        #expect(
            Set(
                storedTasks.compactMap(
                    \.remoteID
                )
            )
            == Set([1, 2])
        )
    }

    @Test(
        "После сетевой ошибки импорт можно повторить"
    )
    func importCanBeRetriedAfterFailure()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let defaultsName =
            "InitialTaskLoaderRetryTests.\(UUID())"

        guard
            let userDefaults =
                UserDefaults(
                    suiteName: defaultsName
                )
        else {
            throw InitialTaskLoaderTestError
                .userDefaultsUnavailable
        }

        defer {
            userDefaults.removePersistentDomain(
                forName: defaultsName
            )
        }

        let todo = TodoDTO(
            id: 42,
            todo: "Загруженная задача",
            completed: false,
            userID: 7
        )

        let apiClient =
            TaskAPIClientSequenceMock(
                results: [
                    .failure(
                        .transport("Нет сети")
                    ),
                    .success([todo])
                ]
            )

        let loader = InitialTaskLoader(
            apiClient: apiClient,
            persistentContainer: container,
            userDefaults: userDefaults
        )

        let firstResult =
            await load(using: loader)

        switch firstResult {
        case .failure(.api(_)):
            break

        default:
            Issue.record(
                "Ожидалась сетевая ошибка"
            )
        }

        let retryCount = try await
            load(using: loader)
            .get()

        #expect(retryCount == 1)
        #expect(apiClient.requestCount == 2)
    }

    private func load(
        using loader: InitialTaskLoading
    ) async -> Result<
        Int,
        InitialTaskLoadError
    > {
        await withCheckedContinuation {
            continuation in

            loader.loadIfNeeded {
                result in

                continuation.resume(
                    returning: result
                )
            }
        }
    }
}
