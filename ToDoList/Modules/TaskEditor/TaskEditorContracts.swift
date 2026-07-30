import Foundation

nonisolated enum TaskEditorMode {

    case create
    case edit(TaskItem)
}

nonisolated struct TaskEditorViewModel {

    let title: String
    let details: String
    let dateText: String
    let shouldFocusTitle: Bool
}

protocol TaskEditorViewInput: AnyObject {

    func display(
        viewModel: TaskEditorViewModel
    )

    func setSaving(_ isSaving: Bool)

    func displayError(message: String)
}

protocol TaskEditorViewOutput: AnyObject {

    func viewDidLoad()

    func didTapBack(
        title: String,
        details: String
    )
}

protocol TaskEditorInteractorInput: AnyObject {

    func saveTask(
        title: String,
        details: String
    )
}

protocol TaskEditorInteractorOutput: AnyObject {

    func didSave(task: TaskItem)

    func didFailSaving(
        error: TaskRepositoryError
    )
}

protocol TaskEditorRouterInput: AnyObject {

    func closeEditor(
        savedTask: TaskItem?
    )
}
