import Foundation

struct TaskListRowViewModel: Identifiable, Hashable {

    let id: UUID
    let title: String
    let details: String
    let dateText: String
    let isCompleted: Bool

    func settingCompletion(
        to isCompleted: Bool
    ) -> TaskListRowViewModel {
        TaskListRowViewModel(
            id: id,
            title: title,
            details: details,
            dateText: dateText,
            isCompleted: isCompleted
        )
    }
}
