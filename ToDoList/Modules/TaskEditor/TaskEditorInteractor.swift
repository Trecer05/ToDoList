import Foundation

final class TaskEditorInteractor {

    weak var output: TaskEditorInteractorOutput?

    private let repository: TaskRepository
    private let mode: TaskEditorMode

    init(
        repository: TaskRepository,
        mode: TaskEditorMode
    ) {
        self.repository = repository
        self.mode = mode
    }
}

extension TaskEditorInteractor:
    TaskEditorInteractorInput {

    func saveTask(
        title: String,
        details: String
    ) {
        switch mode {
        case .create:
            repository.createTask(
                title: title,
                details: details
            ) { [weak self] result in
                self?.handle(result)
            }

        case .edit(let task):
            repository.updateTask(
                id: task.id,
                title: title,
                details: details
            ) { [weak self] result in
                self?.handle(result)
            }
        }
    }

    private func handle(
        _ result:
            Result<
                TaskItem,
                TaskRepositoryError
            >
    ) {
        switch result {
        case .success(let task):
            output?.didSave(task: task)

        case .failure(let error):
            output?.didFailSaving(
                error: error
            )
        }
    }
}
