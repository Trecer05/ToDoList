import Foundation

struct TaskListRowViewModel: Identifiable, Hashable {

    let id: UUID
    let title: String
    let details: String
    let dateText: String
    let isCompleted: Bool
}
