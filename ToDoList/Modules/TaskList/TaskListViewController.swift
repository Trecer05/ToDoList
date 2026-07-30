import UIKit

final class TaskListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground
        title = "Задачи"
        navigationItem.largeTitleDisplayMode = .always
    }
}
