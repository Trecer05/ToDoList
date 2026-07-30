import Foundation

final class TaskEditorPresenter {

    weak var view: TaskEditorViewInput?

    private let interactor:
        TaskEditorInteractorInput

    private let router:
        TaskEditorRouterInput

    private let mode: TaskEditorMode

    private let initialTitle: String
    private let initialDetails: String

    private var isSaving = false

    private lazy var dateFormatter:
        DateFormatter = {

        let formatter = DateFormatter()

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.dateFormat = "dd/MM/yy"

        return formatter
    }()

    init(
        interactor: TaskEditorInteractorInput,
        router: TaskEditorRouterInput,
        mode: TaskEditorMode
    ) {
        self.interactor = interactor
        self.router = router
        self.mode = mode

        switch mode {
        case .create:
            initialTitle = ""
            initialDetails = ""

        case .edit(let task):
            initialTitle = task.title
            initialDetails = task.details
        }
    }

    private func normalized(
        _ text: String
    ) -> String {
        text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}

extension TaskEditorPresenter:
    TaskEditorViewOutput {

    func viewDidLoad() {
        let viewModel: TaskEditorViewModel

        switch mode {
        case .create:
            viewModel = TaskEditorViewModel(
                title: "",
                details: "",
                dateText: dateFormatter.string(
                    from: Date()
                ),
                shouldFocusTitle: true
            )

        case .edit(let task):
            viewModel = TaskEditorViewModel(
                title: task.title,
                details: task.details,
                dateText: dateFormatter.string(
                    from: task.createdAt
                ),
                shouldFocusTitle: false
            )
        }

        view?.display(viewModel: viewModel)
    }

    func didTapBack(
        title: String,
        details: String
    ) {
        guard !isSaving else {
            return
        }

        let normalizedTitle =
            normalized(title)

        let normalizedDetails =
            normalized(details)

        if case .create = mode,
           normalizedTitle.isEmpty,
           normalizedDetails.isEmpty {

            router.closeEditor(
                savedTask: nil
            )

            return
        }

        guard !normalizedTitle.isEmpty else {
            view?.displayError(
                message:
                    "Введите название задачи"
            )

            return
        }

        let hasChanges =
            normalizedTitle !=
                normalized(initialTitle)
            || normalizedDetails !=
                normalized(initialDetails)

        if case .edit(_) = mode,
           !hasChanges {

            router.closeEditor(
                savedTask: nil
            )

            return
        }

        isSaving = true
        view?.setSaving(true)

        interactor.saveTask(
            title: normalizedTitle,
            details: normalizedDetails
        )
    }
}

extension TaskEditorPresenter:
    TaskEditorInteractorOutput {

    func didSave(task: TaskItem) {
        isSaving = false
        view?.setSaving(false)

        router.closeEditor(
            savedTask: task
        )
    }

    func didFailSaving(
        error: TaskRepositoryError
    ) {
        isSaving = false
        view?.setSaving(false)

        view?.displayError(
            message:
                error.localizedDescription
        )
    }
}
