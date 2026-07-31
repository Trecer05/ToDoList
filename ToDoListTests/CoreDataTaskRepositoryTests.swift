import Foundation
import Testing

@testable import ToDoList

@MainActor
@Suite("CoreDataTaskRepository")
struct CoreDataTaskRepositoryTests {

    @Test(
        "Создание, изменение и удаление задачи"
    )
    func createUpdateAndDeleteTask()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let repository =
            CoreDataTaskRepository(
                persistentContainer:
                    container
            )

        let created = try await
            RepositoryAwaiter.create(
                in: repository,
                title: "  Купить молоко  ",
                details: "  Два литра  "
            )
            .get()

        #expect(
            created.title == "Купить молоко"
        )

        #expect(
            created.details == "Два литра"
        )

        #expect(created.isCompleted == false)

        let updated = try await
            RepositoryAwaiter.update(
                in: repository,
                id: created.id,
                title: "Купить продукты",
                details: "Молоко и хлеб"
            )
            .get()

        #expect(
            updated.id == created.id
        )

        #expect(
            updated.title == "Купить продукты"
        )

        #expect(
            updated.details == "Молоко и хлеб"
        )

        _ = try await
            RepositoryAwaiter.delete(
                from: repository,
                id: created.id
            )
            .get()

        let remaining = try await
            RepositoryAwaiter.fetch(
                from: repository
            )
            .get()

        #expect(remaining.isEmpty)
    }

    @Test(
        "Установка статуса идемпотентна"
    )
    func completionStateIsIdempotent()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let repository =
            CoreDataTaskRepository(
                persistentContainer:
                    container
            )

        let task = try await
            RepositoryAwaiter.create(
                in: repository,
                title: "Тестовая задача"
            )
            .get()

        let firstUpdate = try await
            RepositoryAwaiter.setCompletion(
                in: repository,
                id: task.id,
                isCompleted: true
            )
            .get()

        let secondUpdate = try await
            RepositoryAwaiter.setCompletion(
                in: repository,
                id: task.id,
                isCompleted: true
            )
            .get()

        #expect(firstUpdate.isCompleted)
        #expect(secondUpdate.isCompleted)

        let fetched = try await
            RepositoryAwaiter.fetch(
                from: repository
            )
            .get()

        #expect(
            fetched.first?.isCompleted == true
        )
    }

    @Test(
        "Поиск работает по названию и описанию"
    )
    func searchIsCaseInsensitive()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let repository =
            CoreDataTaskRepository(
                persistentContainer:
                    container
            )

        let first = try await
            RepositoryAwaiter.create(
                in: repository,
                title: "Купить молоко",
                details: "Зайти в магазин"
            )
            .get()

        let second = try await
            RepositoryAwaiter.create(
                in: repository,
                title: "Позвонить",
                details: "Напомнить МАМЕ о встрече"
            )
            .get()

        let byTitle = try await
            RepositoryAwaiter.fetch(
                from: repository,
                matching: "молок"
            )
            .get()

        let byDetails = try await
            RepositoryAwaiter.fetch(
                from: repository,
                matching: "маме"
            )
            .get()

        #expect(
            byTitle.map(\.id) == [first.id]
        )

        #expect(
            byDetails.map(\.id) == [second.id]
        )
    }

    @Test(
        "Пустое название отклоняется"
    )
    func emptyTitleIsRejected()
        async throws {

        let container =
            try TestCoreDataStack
                .makeContainer()

        let repository =
            CoreDataTaskRepository(
                persistentContainer:
                    container
            )

        let result = await
            RepositoryAwaiter.create(
                in: repository,
                title: " \n ",
                details: "Описание"
            )

        switch result {
        case .failure(.invalidTitle):
            break

        default:
            Issue.record(
                """
                Ожидалась ошибка \
                TaskRepositoryError.invalidTitle
                """
            )
        }
    }
}
