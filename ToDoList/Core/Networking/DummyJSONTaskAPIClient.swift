import Foundation

nonisolated final class DummyJSONTaskAPIClient:
    TaskAPIClient,
    @unchecked Sendable {

    private enum Constants {
        static let endpoint =
            "https://dummyjson.com/todos"

        static let timeout: TimeInterval = 15

        static let maximumResponseSize =
            5 * 1024 * 1024
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTodos(
        completion: @escaping @Sendable (
            Result<[TodoDTO], TaskAPIError>
        ) -> Void
    ) {
        guard
            let url = URL(
                string: Constants.endpoint
            )
        else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(
            url: url,
            timeoutInterval: Constants.timeout
        )

        request.httpMethod = "GET"
        request.cachePolicy =
            .reloadIgnoringLocalCacheData

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let task = session.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                completion(
                    .failure(
                        .transport(
                            error.localizedDescription
                        )
                    )
                )
                return
            }

            guard
                let httpResponse =
                    response as? HTTPURLResponse
            else {
                completion(
                    .failure(.invalidResponse)
                )
                return
            }

            guard
                (200...299).contains(
                    httpResponse.statusCode
                )
            else {
                completion(
                    .failure(
                        .invalidStatusCode(
                            httpResponse.statusCode
                        )
                    )
                )
                return
            }

            guard
                let data,
                !data.isEmpty
            else {
                completion(
                    .failure(.emptyData)
                )
                return
            }

            guard
                data.count <=
                    Constants.maximumResponseSize
            else {
                completion(
                    .failure(.responseTooLarge)
                )
                return
            }

            do {
                let responseDTO =
                    try JSONDecoder().decode(
                        TodosResponseDTO.self,
                        from: data
                    )

                completion(
                    .success(responseDTO.todos)
                )
            } catch {
                completion(
                    .failure(
                        .decoding(
                            error.localizedDescription
                        )
                    )
                )
            }
        }

        task.resume()
    }
}
