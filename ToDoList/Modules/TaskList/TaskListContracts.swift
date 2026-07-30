import Foundation

protocol TaskListViewInput: AnyObject {

    func display(tasks: [TaskItem])
}

protocol TaskListViewOutput: AnyObject {

    func viewDidLoad()
}

protocol TaskListInteractorInput: AnyObject {

    func fetchTasks()
}

protocol TaskListInteractorOutput: AnyObject {

    func didFetch(tasks: [TaskItem])
}

protocol TaskListRouterInput: AnyObject {

}
