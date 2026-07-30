import UIKit

final class TaskEditorRouter {

    weak var viewController: UIViewController?

    private let onTaskSaved:
        (TaskItem) -> Void

    init(
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        self.onTaskSaved = onTaskSaved
    }
}

extension TaskEditorRouter:
    TaskEditorRouterInput {

    func closeEditor(
        savedTask: TaskItem?
    ) {
        if let savedTask {
            onTaskSaved(savedTask)
        }

        guard let viewController else {
            return
        }

        if let navigationController =
            viewController.navigationController {

            navigationController
                .popViewController(
                    animated: true
                )
        } else {
            viewController.dismiss(
                animated: true
            )
        }
    }
}
