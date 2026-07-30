import Foundation

final class TaskListPresenter {

    weak var view: TaskListViewInput?

    private let interactor: TaskListInteractorInput
    private let router: TaskListRouterInput

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.dateFormat = "dd/MM/yy"

        return formatter
    }()

    init(
        interactor: TaskListInteractorInput,
        router: TaskListRouterInput
    ) {
        self.interactor = interactor
        self.router = router
    }

    private func makeViewModel(
        from task: TaskItem
    ) -> TaskListRowViewModel {
        TaskListRowViewModel(
            id: task.id,
            title: task.title,
            details: task.details,
            dateText: dateFormatter.string(
                from: task.createdAt
            ),
            isCompleted: task.isCompleted
        )
    }
}

extension TaskListPresenter: TaskListViewOutput {

    func viewDidLoad() {
        interactor.fetchTasks()
    }

    func didChangeSearchText(_ text: String) {
        interactor.searchTasks(query: text)
    }

    func didToggleTask(id: UUID) {
        interactor.toggleTask(id: id)
    }
}

extension TaskListPresenter: TaskListInteractorOutput {

    func didFetch(tasks: [TaskItem]) {
        let viewModels = tasks.map(makeViewModel)

        view?.display(tasks: viewModels)
    }
}
