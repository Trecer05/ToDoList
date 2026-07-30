import UIKit

enum TaskListModuleBuilder {

    static func build(
        repository: TaskRepository,
        initialLoader: InitialTaskLoading
    ) -> UIViewController {
        let view = TaskListViewController()

        let interactor = TaskListInteractor(
            repository: repository,
            initialLoader: initialLoader
        )

        let router = TaskListRouter(
            repository: repository
        )

        let presenter = TaskListPresenter(
            interactor: interactor,
            router: router
        )

        view.presenter = presenter
        presenter.view = view
        interactor.output = presenter
        router.viewController = view

        return view
    }
}
