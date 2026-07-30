import Foundation

nonisolated enum TaskEntityMapper {

    static func makeTask(
        from entity: TaskEntity
    ) -> TaskItem? {
        guard
            let id = entity.id,
            let title = entity.title,
            let createdAt = entity.createdAt
        else {
            return nil
        }

        let remoteID: Int?

        if entity.remoteID > 0 {
            remoteID = Int(entity.remoteID)
        } else {
            remoteID = nil
        }

        return TaskItem(
            id: id,
            remoteID: remoteID,
            title: title,
            details: entity.detailsText ?? "",
            createdAt: createdAt,
            isCompleted: entity.isCompleted
        )
    }

    static func apply(
        _ task: TaskItem,
        to entity: TaskEntity
    ) {
        entity.id = task.id
        entity.remoteID = Int64(task.remoteID ?? 0)
        entity.title = task.title
        entity.detailsText = task.details
        entity.createdAt = task.createdAt
        entity.isCompleted = task.isCompleted
    }
}
