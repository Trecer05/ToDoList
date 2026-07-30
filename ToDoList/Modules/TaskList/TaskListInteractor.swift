import Foundation

final class TaskListInteractor {

    weak var output: TaskListInteractorOutput?

    private var tasks: [TaskItem] =
        TaskListInteractor.makePreviewTasks()

    private var currentSearchQuery = ""

    private static func makePreviewTasks() -> [TaskItem] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        func makeDate(
            day: Int,
            month: Int,
            year: Int
        ) -> Date {
            var components = DateComponents()

            components.day = day
            components.month = month
            components.year = year

            return calendar.date(from: components) ?? Date()
        }

        return [
            TaskItem(
                title: "Почитать книгу",
                details: """
                Составить список необходимых продуктов для ужина. \
                Не забыть проверить, что уже есть в холодильнике.
                """,
                createdAt: makeDate(
                    day: 9,
                    month: 10,
                    year: 2024
                ),
                isCompleted: true
            ),

            TaskItem(
                title: "Уборка в квартире",
                details: "Провести генеральную уборку в квартире",
                createdAt: makeDate(
                    day: 2,
                    month: 10,
                    year: 2024
                )
            ),

            TaskItem(
                title: "Заняться спортом",
                details: """
                Сходить в спортзал или сделать тренировку дома. \
                Не забыть про разминку и растяжку!
                """,
                createdAt: makeDate(
                    day: 2,
                    month: 10,
                    year: 2024
                )
            ),

            TaskItem(
                title: "Работа над проектом",
                details: """
                Выделить время для работы над проектом на работе. \
                Сфокусироваться на выполнении важных задач.
                """,
                createdAt: makeDate(
                    day: 9,
                    month: 10,
                    year: 2024
                ),
                isCompleted: true
            ),

            TaskItem(
                title: "Вечерний отдых",
                details: """
                Найти время для расслабления перед сном: \
                посмотреть фильм или послушать музыку
                """,
                createdAt: makeDate(
                    day: 2,
                    month: 10,
                    year: 2024
                )
            ),

            TaskItem(
                title: "Зарядка утром",
                details: "Сделать короткую утреннюю зарядку",
                createdAt: makeDate(
                    day: 3,
                    month: 10,
                    year: 2024
                )
            ),

            TaskItem(
                title: "Позвонить родителям",
                details: "Узнать, как у них дела",
                createdAt: makeDate(
                    day: 4,
                    month: 10,
                    year: 2024
                )
            )
        ]
    }

    private func publishVisibleTasks() {
        let normalizedQuery = currentSearchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            output?.didFetch(tasks: tasks)
            return
        }

        let filteredTasks = tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(
                normalizedQuery
            )
            ||
            task.details.localizedCaseInsensitiveContains(
                normalizedQuery
            )
        }

        output?.didFetch(tasks: filteredTasks)
    }
}

extension TaskListInteractor: TaskListInteractorInput {

    func fetchTasks() {
        publishVisibleTasks()
    }

    func searchTasks(query: String) {
        currentSearchQuery = query
        publishVisibleTasks()
    }

    func toggleTask(id: UUID) {
        guard let index = tasks.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        tasks[index].isCompleted.toggle()

        publishVisibleTasks()
    }
}
