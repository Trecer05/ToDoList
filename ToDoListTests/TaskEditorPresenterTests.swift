import Foundation
import Testing

@testable import ToDoList

@MainActor
private final class TaskEditorViewSpy:
    TaskEditorViewInput {

    private(set) var displayedViewModel:
        TaskEditorViewModel?

    private(set) var savingStates:
        [Bool] = []

    private(set) var errorMessages:
        [String] = []

    func display(
        viewModel: TaskEditorViewModel
    ) {
        displayedViewModel = viewModel
    }

    func setSaving(_ isSaving: Bool) {
        savingStates.append(isSaving)
    }

    func displayError(message: String) {
        errorMessages.append(message)
    }
}

@MainActor
private final class TaskEditorInteractorSpy:
    TaskEditorInteractorInput {

    private(set) var savedValues:
        [(title: String, details: String)] =
            []

    func saveTask(
        title: String,
        details: String
    ) {
        savedValues.append(
            (
                title: title,
                details: details
            )
        )
    }
}

@MainActor
private final class TaskEditorRouterSpy:
    TaskEditorRouterInput {

    private(set) var closeValues:
        [TaskItem?] = []

    func closeEditor(
        savedTask: TaskItem?
    ) {
        closeValues.append(savedTask)
    }
}

@MainActor
@Suite("TaskEditorPresenter")
struct TaskEditorPresenterTests {

    @Test(
        "Пустая новая задача закрывается без сохранения"
    )
    func emptyCreateClosesWithoutSaving() {
        let fixture = makeFixture(
            mode: .create
        )

        fixture.presenter.didTapBack(
            title: "   ",
            details: "\n"
        )

        #expect(
            fixture.interactor
                .savedValues
                .isEmpty
        )

        #expect(
            fixture.router.closeValues.count
                == 1
        )

        #expect(
            fixture.router.closeValues[0]
                == nil
        )
    }

    @Test(
        "Описание без названия не сохраняется"
    )
    func detailsWithoutTitleShowError() {
        let fixture = makeFixture(
            mode: .create
        )

        fixture.presenter.didTapBack(
            title: "",
            details: "Только описание"
        )

        #expect(
            fixture.interactor
                .savedValues
                .isEmpty
        )

        #expect(
            fixture.view.errorMessages
                == ["Введите название задачи"]
        )
    }

    @Test(
        "Неизменённая задача не записывается повторно"
    )
    func unchangedEditClosesWithoutSaving() {
        let task = TaskItem(
            title: "Задача",
            details: "Описание"
        )

        let fixture = makeFixture(
            mode: .edit(task)
        )

        fixture.presenter.didTapBack(
            title: " Задача ",
            details: "Описание\n"
        )

        #expect(
            fixture.interactor
                .savedValues
                .isEmpty
        )

        #expect(
            fixture.router.closeValues.count
                == 1
        )
    }

    @Test(
        "Изменения нормализуются и сохраняются"
    )
    func changedEditIsSaved() {
        let task = TaskItem(
            title: "Старое название",
            details: "Старое описание"
        )

        let fixture = makeFixture(
            mode: .edit(task)
        )

        fixture.presenter.didTapBack(
            title: "  Новое название  ",
            details: "\nНовое описание\n"
        )

        #expect(
            fixture.interactor.savedValues
                .first?.title
                == "Новое название"
        )

        #expect(
            fixture.interactor.savedValues
                .first?.details
                == "Новое описание"
        )

        #expect(
            fixture.view.savingStates
                == [true]
        )
    }

    @Test(
        "Успешное сохранение закрывает редактор"
    )
    func successfulSaveClosesEditor() {
        let fixture = makeFixture(
            mode: .create
        )

        let savedTask = TaskItem(
            title: "Готово"
        )

        fixture.presenter.didSave(
            task: savedTask
        )

        let closedTask =
            fixture.router.closeValues
                .first
                ?? nil

        #expect(
            closedTask?.id == savedTask.id
        )

        #expect(
            fixture.view.savingStates
                == [false]
        )
    }

    private func makeFixture(
        mode: TaskEditorMode
    ) -> (
        presenter: TaskEditorPresenter,
        view: TaskEditorViewSpy,
        interactor: TaskEditorInteractorSpy,
        router: TaskEditorRouterSpy
    ) {
        let view = TaskEditorViewSpy()
        let interactor =
            TaskEditorInteractorSpy()
        let router = TaskEditorRouterSpy()

        let presenter =
            TaskEditorPresenter(
                interactor: interactor,
                router: router,
                mode: mode
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
