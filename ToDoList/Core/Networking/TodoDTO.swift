import Foundation

nonisolated struct TodosResponseDTO: Decodable, Sendable {
    let todos: [TodoDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

nonisolated struct TodoDTO: Decodable, Sendable {
    let id: Int
    let todo: String
    let completed: Bool
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case id
        case todo
        case completed
        case userID = "userId"
    }
}
