import Foundation

final class TaskListPresenter {

    weak var view: TaskListViewInput?

    private let interactor: TaskListInteractorInput
    private let router: TaskListRouterInput

    init(
        interactor: TaskListInteractorInput,
        router: TaskListRouterInput
    ) {
        self.interactor = interactor
        self.router = router
    }
}

extension TaskListPresenter: TaskListViewOutput {

    func viewDidLoad() {
        interactor.fetchTasks()
    }
}

extension TaskListPresenter: TaskListInteractorOutput {

    func didFetch(tasks: [TaskItem]) {
        view?.display(tasks: tasks)
    }
}
