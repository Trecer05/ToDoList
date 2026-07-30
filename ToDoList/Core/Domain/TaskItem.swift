import Foundation

nonisolated struct TaskItem: Identifiable, Hashable, Sendable {

    let id: UUID
    let remoteID: Int?

    var title: String
    var details: String
    let createdAt: Date
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        remoteID: Int? = nil,
        title: String,
        details: String = "",
        createdAt: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.details = details
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }
}
