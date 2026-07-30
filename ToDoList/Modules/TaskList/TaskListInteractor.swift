import Foundation

final class TaskListInteractor {

    weak var output: TaskListInteractorOutput?

    private let repository: TaskRepository

    private var currentSearchQuery = ""

    init(
        repository: TaskRepository
    ) {
        self.repository = repository
    }

    private func publishTasks() {
        do {
            let tasks = try repository.fetchTasks(
                matching: currentSearchQuery
            )

            output?.didFetch(tasks: tasks)
        } catch {
            NSLog(
                """
                Failed to fetch tasks: \
                \(error.localizedDescription)
                """
            )
        }
    }
}

extension TaskListInteractor: TaskListInteractorInput {

    func fetchTasks() {
        publishTasks()
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
            NSLog(
                """
                Failed to toggle task: \
                \(error.localizedDescription)
                """
            )
        }
    }
}
