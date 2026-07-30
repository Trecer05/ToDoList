import UIKit

final class TaskListRouter {

    weak var viewController: UIViewController?

    private let repository: TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }
}

extension TaskListRouter: TaskListRouterInput {

    func showCreateTask(
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        let editorViewController =
            TaskEditorModuleBuilder.build(
                repository: repository,
                mode: .create,
                onTaskSaved: onTaskSaved
            )

        viewController?
            .navigationController?
            .pushViewController(
                editorViewController,
                animated: true
            )
    }
}
