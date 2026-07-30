import UIKit
import CoreData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Application lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    // MARK: - Scene lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession:
            UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions:
            Set<UISceneSession>
    ) {
    }

    // MARK: - Core Data

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "ToDoList"
        )

        container.persistentStoreDescriptions.forEach {
            description in

            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores {
            storeDescription,
            error in

            if let error {
                NSLog(
                    """
                    Core Data store failed to load: \
                    \(error.localizedDescription)
                    """
                )

                return
            }

            NSLog(
                """
                Core Data store loaded: \
                \(storeDescription.url?.absoluteString ?? "unknown")
                """
            )
        }

        container.viewContext.name = "ViewContext"

        container.viewContext.mergePolicy =
            NSMergeByPropertyObjectTrumpMergePolicy

        container.viewContext
            .automaticallyMergesChangesFromParent = true

        container.viewContext.undoManager = nil

        return container
    }()

    // MARK: - Saving

    func saveViewContext() {
        let context = persistentContainer.viewContext

        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            context.rollback()

            NSLog(
                """
                Core Data save failed: \
                \(error.localizedDescription)
                """
            )
        }
    }
}
