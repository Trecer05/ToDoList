import Foundation

protocol TaskRepository: AnyObject {

    func fetchTasks(
        matching query: String
    ) throws -> [TaskItem]

    func toggleTask(
        id: UUID
    ) throws
}
