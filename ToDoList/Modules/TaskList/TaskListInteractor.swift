import Foundation
import OSLog

final class TaskListInteractor {

    weak var output: TaskListInteractorOutput?

    private let repository: TaskRepository
    private let initialLoader: InitialTaskLoading

    private var currentSearchQuery = ""
    private var didStartInitialLoading = false

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
        do {
            let tasks =
                try repository.fetchTasks(
                    matching: currentSearchQuery
                )

            output?.didFetch(tasks: tasks)
        } catch {
            logger.error(
                """
                Failed to fetch tasks: \
                \(error.localizedDescription, privacy: .public)
                """
            )
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
        // Сначала моментально отображаем всё,
        // что уже сохранено локально.
        publishTasks()

        // Затем при необходимости запускаем
        // первоначальную загрузку из API.
        startInitialLoadingIfNeeded()
    }

    func searchTasks(query: String) {
        currentSearchQuery = query
        publishTasks()
    }

    func toggleTask(id: UUID) {
        do {
            try repository.toggleTask(id: id)
            publishTasks()
        } catch {
            logger.error(
                """
                Failed to toggle task: \
                \(error.localizedDescription, privacy: .public)
                """
            )
        }
    }
}
