import Foundation
import Testing

@testable import ToDoList

@MainActor
private final class TaskListViewSpy:
    TaskListViewInput {

    private(set) var displayedTasks:
        [[TaskListRowViewModel]] = []

    private(set) var errors:
        [(title: String, message: String)] =
            []

    private(set) var initialLoadErrors:
        [String] = []

    func display(
        tasks: [TaskListRowViewModel]
    ) {
        displayedTasks.append(tasks)
    }

    func displayError(
        title: String,
        message: String
    ) {
        errors.append(
            (
                title: title,
                message: message
            )
        )
    }

    func displayInitialLoadError(
        message: String
    ) {
        initialLoadErrors.append(message)
    }
}

@MainActor
private final class TaskListInteractorSpy:
    TaskListInteractorInput {

    private(set) var fetchCount = 0
    private(set) var searchQueries:
        [String] = []

    private(set) var completionChanges:
        [(id: UUID, isCompleted: Bool)] =
            []

    private(set) var deletedIDs:
        [UUID] = []

    private(set) var retryCount = 0

    func fetchTasks() {
        fetchCount += 1
    }

    func searchTasks(query: String) {
        searchQueries.append(query)
    }

    func setTaskCompletion(
        id: UUID,
        isCompleted: Bool
    ) {
        completionChanges.append(
            (
                id: id,
                isCompleted: isCompleted
            )
        )
    }

    func deleteTask(id: UUID) {
        deletedIDs.append(id)
    }

    func retryInitialLoading() {
        retryCount += 1
    }
}

@MainActor
private final class TaskListRouterSpy:
    TaskListRouterInput {

    private(set) var editedTask:
        TaskItem?

    private(set) var sharedText:
        String?

    private(set) var deleteTitle:
        String?

    private var deleteConfirmation:
        (() -> Void)?

    func showCreateTask(
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
    }

    func showEditTask(
        task: TaskItem,
        onTaskSaved:
            @escaping (TaskItem) -> Void
    ) {
        editedTask = task
    }

    func showShareSheet(text: String) {
        sharedText = text
    }

    func showDeleteConfirmation(
        taskTitle: String,
        onConfirm: @escaping () -> Void
    ) {
        deleteTitle = taskTitle
        deleteConfirmation = onConfirm
    }

    func confirmDeletion() {
        deleteConfirmation?()
    }
}

@MainActor
@Suite("TaskListPresenter")
struct TaskListPresenterTests {

    @Test(
        "Нажатие на задачу открывает редактирование"
    )
    func selectionOpensEditor() {
        let fixture = makeFixture()

        let task = TaskItem(
            title: "Открыть меня",
            details: "Описание"
        )

        fixture.presenter.didFetch(
            tasks: [task]
        )

        fixture.presenter.didSelectTask(
            id: task.id
        )

        #expect(
            fixture.router.editedTask?.id
                == task.id
        )
    }

    @Test(
        "Удаление начинается только после подтверждения"
    )
    func deletionRequiresConfirmation() {
        let fixture = makeFixture()

        let task = TaskItem(
            title: "Удаляемая задача"
        )

        fixture.presenter.didFetch(
            tasks: [task]
        )

        fixture.presenter
            .didRequestDeleteTask(
                id: task.id
            )

        #expect(
            fixture.interactor
                .deletedIDs
                .isEmpty
        )

        #expect(
            fixture.router.deleteTitle
                == task.title
        )

        fixture.router.confirmDeletion()

        #expect(
            fixture.interactor.deletedIDs
                == [task.id]
        )
    }

    @Test(
        "Шаринг содержит данные и статус задачи"
    )
    func sharingContainsTaskData() {
        let fixture = makeFixture()

        let task = TaskItem(
            title: "Поделиться задачей",
            details: "Важное описание",
            isCompleted: true
        )

        fixture.presenter.didFetch(
            tasks: [task]
        )

        fixture.presenter
            .didRequestShareTask(
                id: task.id
            )

        let text =
            fixture.router.sharedText
            ?? ""

        #expect(
            text.contains(task.title)
        )

        #expect(
            text.contains(task.details)
        )

        #expect(
            text.contains("Статус: выполнено")
        )
    }

    @Test(
        "Передаётся конкретное состояние выполнения"
    )
    func completionUsesExplicitState() {
        let fixture = makeFixture()

        let task = TaskItem(
            title: "Переключить"
        )

        fixture.presenter.didFetch(
            tasks: [task]
        )

        fixture.presenter
            .didSetTaskCompletion(
                id: task.id,
                isCompleted: true
            )

        #expect(
            fixture.interactor
                .completionChanges
                .first?
                .id
                == task.id
        )

        #expect(
            fixture.interactor
                .completionChanges
                .first?
                .isCompleted
                == true
        )
    }

    @Test(
        "Сетевую ошибку стартового импорта можно повторить"
    )
    func initialImportFailureCanRetry() {
        let fixture = makeFixture()

        fixture.presenter.didFail(
            .initialImport(
                .api(
                    .transport("Нет сети")
                )
            )
        )

        #expect(
            fixture.view
                .initialLoadErrors
                .count
                == 1
        )

        fixture.presenter
            .didTapRetryInitialLoad()

        #expect(
            fixture.interactor.retryCount
                == 1
        )
    }

    private func makeFixture()
        -> (
            presenter: TaskListPresenter,
            view: TaskListViewSpy,
            interactor: TaskListInteractorSpy,
            router: TaskListRouterSpy
        ) {

        let view = TaskListViewSpy()
        let interactor =
            TaskListInteractorSpy()
        let router = TaskListRouterSpy()

        let presenter =
            TaskListPresenter(
                interactor: interactor,
                router: router
            )

        presenter.view = view

        return (
            presenter: presenter,
            view: view,
            interactor: interactor,
            router: router
        )
    }
}
