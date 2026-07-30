import Foundation

nonisolated enum TaskAPIError: LocalizedError, Sendable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case invalidStatusCode(Int)
    case emptyData
    case responseTooLarge
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Не удалось сформировать URL запроса"

        case .transport(let description):
            return "Ошибка сети: \(description)"

        case .invalidResponse:
            return "Сервер вернул некорректный ответ"

        case .invalidStatusCode(let code):
            return "Сервер вернул HTTP-код \(code)"

        case .emptyData:
            return "Сервер вернул пустой ответ"

        case .responseTooLarge:
            return "Ответ сервера превышает допустимый размер"

        case .decoding(let description):
            return "Не удалось обработать JSON: \(description)"
        }
    }
}
