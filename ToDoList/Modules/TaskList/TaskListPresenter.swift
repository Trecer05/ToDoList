import Foundation

final class TaskListPresenter {

    weak var view: TaskListViewInput?

    private let interactor:
        TaskListInteractorInput

    private let router:
        TaskListRouterInput

    private var tasksByID:
        [UUID: TaskItem] = [:]

    private lazy var dateFormatter:
        DateFormatter = {

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

    private func task(
        withID id: UUID
    ) -> TaskItem? {
        guard let task = tasksByID[id] else {
            view?.displayError(
                title: "Задача недоступна",
                message:
                    "Список уже изменился. Обновляем данные."
            )

            interactor.fetchTasks()
            return nil
        }

        return task
    }

    private func showEditor(
        for task: TaskItem
    ) {
        router.showEditTask(
            task: task
        ) { [weak self] _ in
            self?.interactor.fetchTasks()
        }
    }

    private func makeShareText(
        for task: TaskItem
    ) -> String {
        var sections = [task.title]

        let details =
            task.details.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !details.isEmpty {
            sections.append(details)
        }

        sections.append(
            """
            Дата создания: \
            \(dateFormatter.string(from: task.createdAt))
            """
        )

        sections.append(
            task.isCompleted
                ? "Статус: выполнено"
                : "Статус: не выполнено"
        )

        return sections.joined(
            separator: "\n\n"
        )
    }
}

extension TaskListPresenter:
    TaskListViewOutput {

    func viewDidLoad() {
        interactor.fetchTasks()
    }

    func didChangeSearchText(
        _ text: String
    ) {
        interactor.searchTasks(
            query: text
        )
    }

    func didSetTaskCompletion(
        id: UUID,
        isCompleted: Bool
    ) {
        if let currentTask = tasksByID[id] {
            var updatedTask = currentTask
            updatedTask.isCompleted = isCompleted
            tasksByID[id] = updatedTask
        }

        interactor.setTaskCompletion(
            id: id,
            isCompleted: isCompleted
        )
    }

    func didTapAddTask() {
        router.showCreateTask {
            [weak self] _ in

            self?.interactor.fetchTasks()
        }
    }

    func didSelectTask(id: UUID) {
        guard let task = task(withID: id) else {
            return
        }

        showEditor(for: task)
    }

    func didRequestEditTask(id: UUID) {
        guard let task = task(withID: id) else {
            return
        }

        showEditor(for: task)
    }

    func didRequestShareTask(id: UUID) {
        guard let task = task(withID: id) else {
            return
        }

        router.showShareSheet(
            text: makeShareText(
                for: task
            )
        )
    }

    func didRequestDeleteTask(id: UUID) {
        guard let task = task(withID: id) else {
            return
        }

        router.showDeleteConfirmation(
            taskTitle: task.title
        ) { [weak self] in
            self?.interactor.deleteTask(
                id: id
            )
        }
    }

    func didTapRetryInitialLoad() {
        interactor.retryInitialLoading()
    }
}

extension TaskListPresenter:
    TaskListInteractorOutput {

    func didFetch(tasks: [TaskItem]) {
        tasksByID = tasks.reduce(
            into: [:]
        ) { result, task in
            result[task.id] = task
        }

        let viewModels =
            tasks.map(makeViewModel)

        view?.display(
            tasks: viewModels
        )
    }

    func didFail(
        _ failure: TaskListFailure
    ) {
        switch failure {
        case .fetch(let error):
            view?.displayError(
                title:
                    "Не удалось загрузить задачи",
                message:
                    error.localizedDescription
            )

        case .completion(let error):
            view?.displayError(
                title:
                    "Не удалось изменить задачу",
                message:
                    error.localizedDescription
            )

        case .deletion(let error):
            view?.displayError(
                title:
                    "Не удалось удалить задачу",
                message:
                    error.localizedDescription
            )

        case .initialImport(let error):
            view?.displayInitialLoadError(
                message:
                    error.localizedDescription
            )
        }
    }
}
