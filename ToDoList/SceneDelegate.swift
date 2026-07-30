import UIKit
import CoreData

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions:
            UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate =
                UIApplication.shared.delegate as? AppDelegate
        else {
            assertionFailure(
                "Application dependencies are unavailable"
            )
            return
        }

        let repository = CoreDataTaskRepository(
            context: appDelegate
                .persistentContainer
                .viewContext
        )

        let rootViewController =
            TaskListModuleBuilder.build(
                repository: repository
            )

        let navigationController =
            UINavigationController(
                rootViewController: rootViewController
            )

        navigationController
            .navigationBar
            .prefersLargeTitles = false

        let window = UIWindow(
            windowScene: windowScene
        )

        window.rootViewController = navigationController
        window.overrideUserInterfaceStyle = .dark

        self.window = window

        window.makeKeyAndVisible()
    }
}
