import Foundation

nonisolated protocol TaskAPIClient: AnyObject {

    func fetchTodos(
        completion: @escaping @Sendable (
            Result<[TodoDTO], TaskAPIError>
        ) -> Void
    )
}
