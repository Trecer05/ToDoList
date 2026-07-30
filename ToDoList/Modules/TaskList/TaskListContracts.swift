import Foundation

protocol TaskListViewInput: AnyObject {

    func display(tasks: [TaskListRowViewModel])
}

protocol TaskListViewOutput: AnyObject {

    func viewDidLoad()

    func didChangeSearchText(_ text: String)

    func didToggleTask(id: UUID)
}

protocol TaskListInteractorInput: AnyObject {

    func fetchTasks()

    func searchTasks(query: String)

    func toggleTask(id: UUID)
}

protocol TaskListInteractorOutput: AnyObject {

    func didFetch(tasks: [TaskItem])
}

protocol TaskListRouterInput: AnyObject {

}
