import Foundation

nonisolated enum TaskRepositoryError:
    LocalizedError,
    Sendable {

    case invalidTitle
    case titleTooLong(maximum: Int)
    case detailsTooLong(maximum: Int)
    case taskNotFound
    case corruptedTask
    case persistence(String)

    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "Название задачи не может быть пустым"

        case .titleTooLong(let maximum):
            return """
            Название задачи не может быть длиннее \
            \(maximum) символов
            """

        case .detailsTooLong(let maximum):
            return """
            Описание задачи не может быть длиннее \
            \(maximum) символов
            """

        case .taskNotFound:
            return "Задача не найдена"

        case .corruptedTask:
            return "Сохранённая задача повреждена"

        case .persistence(let description):
            return """
            Ошибка хранилища: \(description)
            """
        }
    }
}

nonisolated protocol TaskRepository: AnyObject {

    func fetchTasks(
        matching query: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    [TaskItem],
                    TaskRepositoryError
                >
            ) -> Void
    )

    func createTask(
        title: String,
        details: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    )

    func updateTask(
        id: UUID,
        title: String,
        details: String,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    )

    func deleteTask(
        id: UUID,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    Void,
                    TaskRepositoryError
                >
            ) -> Void
    )

    func setTaskCompletion(
        id: UUID,
        isCompleted: Bool,
        completion:
            @escaping @MainActor @Sendable (
                Result<
                    TaskItem,
                    TaskRepositoryError
                >
            ) -> Void
    )
}
