import UIKit

enum TaskEditorModuleBuilder {

    static func build(
        repository: TaskRepository,
        mode: TaskEditorMode,
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) -> UIViewController {
        let view = TaskEditorViewController()

        let interactor = TaskEditorInteractor(
            repository: repository,
            mode: mode
        )

        let router = TaskEditorRouter(
            onTaskSaved: onTaskSaved
        )

        let presenter = TaskEditorPresenter(
            interactor: interactor,
            router: router,
            mode: mode
        )

        view.presenter = presenter
        presenter.view = view
        interactor.output = presenter
        router.viewController = view

        return view
    }
}
