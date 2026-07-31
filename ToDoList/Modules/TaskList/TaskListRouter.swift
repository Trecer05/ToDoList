import UIKit

final class TaskListRouter {

    weak var viewController:
        UIViewController?

    private let repository:
        TaskRepository

    init(repository: TaskRepository) {
        self.repository = repository
    }

    private var presentationHost:
        UIViewController? {

        if let topViewController =
            viewController?
                .navigationController?
                .topViewController {

            return topViewController
        }

        return viewController
    }

    private func openEditor(
        mode: TaskEditorMode,
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        let editorViewController =
            TaskEditorModuleBuilder.build(
                repository: repository,
                mode: mode,
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

extension TaskListRouter:
    TaskListRouterInput {

    func showCreateTask(
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        openEditor(
            mode: .create,
            onTaskSaved: onTaskSaved
        )
    }

    func showEditTask(
        task: TaskItem,
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        openEditor(
            mode: .edit(task),
            onTaskSaved: onTaskSaved
        )
    }

    func showShareSheet(text: String) {
        guard
            let host = presentationHost,
            host.presentedViewController == nil
        else {
            return
        }

        let activityViewController =
            UIActivityViewController(
                activityItems: [text],
                applicationActivities: nil
            )

        if let popover =
            activityViewController
                .popoverPresentationController {

            popover.sourceView = host.view

            popover.sourceRect = CGRect(
                x: host.view.bounds.midX,
                y: host.view.bounds.maxY - 44,
                width: 1,
                height: 1
            )

            popover.permittedArrowDirections = []
        }

        host.present(
            activityViewController,
            animated: true
        )
    }

    func showDeleteConfirmation(
        taskTitle: String,
        onConfirm: @escaping () -> Void
    ) {
        guard
            let host = presentationHost,
            host.presentedViewController == nil
        else {
            return
        }

        let maximumVisibleTitleLength = 60

        let visibleTitle: String

        if taskTitle.count >
            maximumVisibleTitleLength {

            visibleTitle =
                String(
                    taskTitle.prefix(
                        maximumVisibleTitleLength
                    )
                )
                + "…"
        } else {
            visibleTitle = taskTitle
        }

        let alert = UIAlertController(
            title:
                "Удалить «\(visibleTitle)»?",
            message:
                "Это действие нельзя отменить.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Отмена",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Удалить",
                style: .destructive
            ) { _ in
                onConfirm()
            }
        )

        host.present(
            alert,
            animated: true
        )
    }
}
