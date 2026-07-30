import UIKit

final class ViewController: UIViewController {

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
