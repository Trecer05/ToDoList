import Foundation

final class TaskListInteractor {

    weak var output: TaskListInteractorOutput?
}

extension TaskListInteractor: TaskListInteractorInput {

    func fetchTasks() {
        output?.didFetch(tasks: [])
    }
}
