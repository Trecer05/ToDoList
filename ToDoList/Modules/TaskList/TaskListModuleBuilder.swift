import UIKit

enum TaskListModuleBuilder {

    static func build(
        repository: TaskRepository
    ) -> UIViewController {
        let view = TaskListViewController()

        let interactor = TaskListInteractor(
            repository: repository
        )

        let router = TaskListRouter()

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
