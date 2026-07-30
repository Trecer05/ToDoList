import Foundation
import OSLog

final class TaskListInteractor {

    weak var output: TaskListInteractorOutput?

    private let repository: TaskRepository
    private let initialLoader: InitialTaskLoading

    private var currentSearchQuery = ""
    private var didStartInitialLoading = false

    // Номер запроса защищает экран
    // от отображения устаревшего результата.
    private var fetchRequestID = 0

    private let logger = Logger(
        subsystem:
            Bundle.main.bundleIdentifier
            ?? "ToDoList",
        category: "TaskListInteractor"
    )

    init(
        repository: TaskRepository,
        initialLoader: InitialTaskLoading
    ) {
        self.repository = repository
        self.initialLoader = initialLoader
    }

    private func publishTasks() {
        fetchRequestID += 1

        let currentRequestID =
            fetchRequestID

        let query = currentSearchQuery

        repository.fetchTasks(
            matching: query
        ) { [weak self] result in
            guard let self else { return }

            // Если после этого запроса уже был
            // отправлен новый — старый игнорируем.
            guard
                currentRequestID ==
                    self.fetchRequestID
            else {
                return
            }

            switch result {
            case .success(let tasks):
                self.output?.didFetch(
                    tasks: tasks
                )

            case .failure(let error):
                self.logger.error(
                    """
                    Failed to fetch tasks: \
                    \(error.localizedDescription, privacy: .public)
                    """
                )
            }
        }
    }

    private func startInitialLoadingIfNeeded() {
        guard !didStartInitialLoading else {
            return
        }

        didStartInitialLoading = true

        initialLoader.loadIfNeeded {
            [weak self] result in

            guard let self else { return }

            switch result {
            case .success(let importedCount):
                self.logger.info(
                    """
                    Initial import completed. \
                    Imported tasks: \(importedCount)
                    """
                )

                self.publishTasks()

            case .failure(let error):
                self.logger.error(
                    """
                    Initial import failed: \
                    \(error.localizedDescription, privacy: .public)
                    """
                )
            }
        }
    }
}

extension TaskListInteractor:
    TaskListInteractorInput {

    func fetchTasks() {
        publishTasks()
        startInitialLoadingIfNeeded()
    }

    func searchTasks(query: String) {
        currentSearchQuery = query
        publishTasks()
    }

    func toggleTask(id: UUID) {
        repository.toggleTask(
            id: id
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                self.publishTasks()

            case .failure(let error):
                self.logger.error(
                    """
                    Failed to toggle task: \
                    \(error.localizedDescription, privacy: .public)
                    """
                )
            }
        }
    }
}
