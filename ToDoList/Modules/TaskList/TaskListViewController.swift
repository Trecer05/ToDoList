import UIKit

final class TaskListViewController: UIViewController {

    var presenter: TaskListViewOutput?

    private var tasks: [TaskItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()

        guard let presenter else {
            assertionFailure("TaskListPresenter is not configured")
            return
        }

        presenter.viewDidLoad()
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground

        title = "Задачи"
        navigationItem.largeTitleDisplayMode = .always
    }
}

extension TaskListViewController: TaskListViewInput {

    func display(tasks: [TaskItem]) {
        self.tasks = tasks
    }
}
