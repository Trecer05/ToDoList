import Foundation

nonisolated enum TaskListFailure:
    Sendable {

    case fetch(TaskRepositoryError)
    case completion(TaskRepositoryError)
    case deletion(TaskRepositoryError)
    case initialImport(InitialTaskLoadError)
}

protocol TaskListViewInput: AnyObject {

    func display(
        tasks: [TaskListRowViewModel]
    )

    func displayError(
        title: String,
        message: String
    )

    func displayInitialLoadError(
        message: String
    )
}

protocol TaskListViewOutput: AnyObject {

    func viewDidLoad()

    func didChangeSearchText(_ text: String)

    func didSetTaskCompletion(
        id: UUID,
        isCompleted: Bool
    )

    func didTapAddTask()

    func didSelectTask(id: UUID)

    func didRequestEditTask(id: UUID)

    func didRequestShareTask(id: UUID)

    func didRequestDeleteTask(id: UUID)

    func didTapRetryInitialLoad()
}

protocol TaskListInteractorInput: AnyObject {

    func fetchTasks()

    func searchTasks(query: String)

    func setTaskCompletion(
        id: UUID,
        isCompleted: Bool
    )

    func deleteTask(id: UUID)

    func retryInitialLoading()
}

protocol TaskListInteractorOutput: AnyObject {

    func didFetch(tasks: [TaskItem])

    func didFail(_ failure: TaskListFailure)
}

protocol TaskListRouterInput: AnyObject {

    func showCreateTask(
        onTaskSaved:
            @escaping (TaskItem) -> Void
    )

    func showEditTask(
        task: TaskItem,
        onTaskSaved:
            @escaping (TaskItem) -> Void
    )

    func showShareSheet(text: String)

    func showDeleteConfirmation(
        taskTitle: String,
        onConfirm: @escaping () -> Void
    )
}
