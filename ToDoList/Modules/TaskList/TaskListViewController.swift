import UIKit

private final class TaskSearchTextField: UITextField {

    private enum Metrics {
        static let iconSize: CGFloat = 16
        static let leftIconInset: CGFloat = 7
        static let rightIconInset: CGFloat = 8
        static let textLeftInset: CGFloat = 29
        static let textRightInset: CGFloat = 30
    }

    override func leftViewRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        CGRect(
            x: Metrics.leftIconInset,
            y: (bounds.height - Metrics.iconSize) / 2,
            width: Metrics.iconSize,
            height: Metrics.iconSize
        )
    }

    override func rightViewRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        CGRect(
            x: bounds.width
                - Metrics.rightIconInset
                - Metrics.iconSize,
            y: (bounds.height - Metrics.iconSize) / 2,
            width: Metrics.iconSize,
            height: Metrics.iconSize
        )
    }

    override func textRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        bounds.inset(
            by: UIEdgeInsets(
                top: 0,
                left: Metrics.textLeftInset,
                bottom: 0,
                right: Metrics.textRightInset
            )
        )
    }

    override func editingRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func placeholderRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        textRect(forBounds: bounds)
    }
}

final class TaskListViewController: UIViewController {

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let titleTopInset: CGFloat = 10
        static let titleToSearchSpacing: CGFloat = 10
        static let searchHeight: CGFloat = 36
        static let searchToListSpacing: CGFloat = 14
        static let bottomBarHeight: CGFloat = 84
        static let bottomBarContentTopInset: CGFloat = 20
    }

    // MARK: - Dependencies

    var presenter: TaskListViewOutput?

    // MARK: - State

    private var tasksByID: [UUID: TaskListRowViewModel] = [:]

    private lazy var dataSource = makeDataSource()

    private var canPresentAlert: Bool {
        let isVisibleController: Bool

        if let navigationController {
            isVisibleController =
                navigationController
                    .topViewController === self
        } else {
            isVisibleController =
                view.window != nil
        }

        return view.window != nil
            && isVisibleController
            && presentedViewController == nil
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.text = "Задачи"
        label.textColor = .white
        label.font = .systemFont(
            ofSize: 34,
            weight: .bold
        )

        label.accessibilityIdentifier =
            "taskList.title"

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let searchTextField: TaskSearchTextField = {
        let textField = TaskSearchTextField()

        textField.backgroundColor = UIColor(
            white: 0.15,
            alpha: 1
        )

        textField.textColor = .white
        textField.tintColor = .systemYellow

        textField.font = .systemFont(
            ofSize: 16,
            weight: .regular
        )

        textField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [
                .foregroundColor: UIColor.secondaryLabel
            ]
        )

        textField.borderStyle = .none
        textField.layer.cornerRadius = 10
        textField.clipsToBounds = true

        textField.clearButtonMode = .never
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .sentences

        let symbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 15,
                weight: .regular
            )

        let searchImageView = UIImageView(
            image: UIImage(
                systemName: "magnifyingglass",
                withConfiguration: symbolConfiguration
            )
        )

        searchImageView.tintColor = .secondaryLabel
        searchImageView.contentMode = .scaleAspectFit

        textField.leftView = searchImageView
        textField.leftViewMode = .always

        let microphoneImageView = UIImageView(
            image: UIImage(
                systemName: "mic.fill",
                withConfiguration: symbolConfiguration
            )
        )

        microphoneImageView.tintColor = .secondaryLabel
        microphoneImageView.contentMode = .scaleAspectFit

        textField.rightView = microphoneImageView
        textField.rightViewMode = .always

        textField.accessibilityLabel = "Поиск задач"
        textField.accessibilityIdentifier =
            "taskList.search"

        textField.translatesAutoresizingMaskIntoConstraints = false

        return textField
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(
            frame: .zero,
            style: .plain
        )

        tableView.backgroundColor = .black

        tableView.separatorColor = UIColor(
            white: 0.22,
            alpha: 1
        )

        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.delaysContentTouches = false
        tableView.accessibilityIdentifier =
            "taskList.table"

        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    private let bottomBarView: UIView = {
        let view = UIView()

        view.backgroundColor = UIColor(
            white: 0.15,
            alpha: 1
        )

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let taskCountLabel: UILabel = {
        let label = UILabel()

        label.text = "0 задач"
        label.textColor = .white

        label.font = .systemFont(
            ofSize: 12,
            weight: .regular
        )

        label.textAlignment = .center
        label.accessibilityIdentifier =
            "taskList.count"

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)

        let configuration = UIImage.SymbolConfiguration(
            pointSize: 22,
            weight: .regular
        )

        let image = UIImage(
            systemName: "square.and.pencil",
            withConfiguration: configuration
        )

        button.setImage(image, for: .normal)
        button.tintColor = .systemYellow
        button.accessibilityLabel = "Добавить задачу"
        button.accessibilityIdentifier =
            "taskList.add"

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureHierarchy()
        configureConstraints()
        configureTableView()
        configureActions()

        guard let presenter else {
            assertionFailure(
                "TaskListPresenter is not configured"
            )
            return
        }

        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(
            true,
            animated: animated
        )
    }

    // MARK: - Configuration

    private func configureAppearance() {
        view.backgroundColor = .black
    }

    private func configureHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(searchTextField)
        view.addSubview(tableView)
        view.addSubview(bottomBarView)

        bottomBarView.addSubview(taskCountLabel)
        bottomBarView.addSubview(addButton)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Layout.titleTopInset
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.horizontalInset
            ),

            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -Layout.horizontalInset
            ),

            searchTextField.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: Layout.titleToSearchSpacing
            ),

            searchTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.horizontalInset
            ),

            searchTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Layout.horizontalInset
            ),

            searchTextField.heightAnchor.constraint(
                equalToConstant: Layout.searchHeight
            ),

            tableView.topAnchor.constraint(
                equalTo: searchTextField.bottomAnchor,
                constant: Layout.searchToListSpacing
            ),

            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.horizontalInset
            ),

            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Layout.horizontalInset
            ),

            tableView.bottomAnchor.constraint(
                equalTo: bottomBarView.topAnchor
            ),

            bottomBarView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),

            bottomBarView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            bottomBarView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            bottomBarView.heightAnchor.constraint(
                equalToConstant: Layout.bottomBarHeight
            ),

            taskCountLabel.topAnchor.constraint(
                equalTo: bottomBarView.topAnchor,
                constant: Layout.bottomBarContentTopInset
            ),

            taskCountLabel.centerXAnchor.constraint(
                equalTo: bottomBarView.centerXAnchor
            ),

            addButton.centerYAnchor.constraint(
                equalTo: taskCountLabel.centerYAnchor
            ),

            addButton.trailingAnchor.constraint(
                equalTo: bottomBarView.trailingAnchor,
                constant: -Layout.horizontalInset
            ),

            addButton.widthAnchor.constraint(
                equalToConstant: 44
            ),

            addButton.heightAnchor.constraint(
                equalToConstant: 44
            )
        ])
    }

    private func configureTableView() {
        tableView.register(
            TaskListCell.self,
            forCellReuseIdentifier: TaskListCell.reuseIdentifier
        )

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.delegate = self

        _ = dataSource
    }

    private func configureActions() {
        searchTextField.addTarget(
            self,
            action: #selector(searchTextDidChange),
            for: .editingChanged
        )

        searchTextField.delegate = self

        addButton.addTarget(
            self,
            action: #selector(addButtonTapped),
            for: .touchUpInside
        )
    }

    // MARK: - Data Source

    private func makeDataSource()
        -> UITableViewDiffableDataSource<Int, UUID> {

        UITableViewDiffableDataSource<Int, UUID>(
            tableView: tableView
        ) { [weak self] tableView, _, taskID in
            guard
                let self,
                let task = self.tasksByID[taskID],
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: TaskListCell.reuseIdentifier
                ) as? TaskListCell
            else {
                return nil
            }

            cell.configure(with: task)

            cell.onCompletionTapped = {
                [weak self] isCompleted in

                guard
                    let self,
                    let currentTask = self.tasksByID[taskID]
                else {
                    return
                }

                self.tasksByID[taskID] =
                    currentTask.settingCompletion(
                        to: isCompleted
                    )

                self.presenter?
                    .didSetTaskCompletion(
                        id: taskID,
                        isCompleted: isCompleted
                    )
            }

            return cell
        }
    }

    // MARK: - Actions

    @objc
    private func searchTextDidChange() {
        presenter?.didChangeSearchText(
            searchTextField.text ?? ""
        )
    }

    @objc
    private func addButtonTapped() {
        presenter?.didTapAddTask()
    }

    // MARK: - Task Count

    private func makeTaskCountText(
        for count: Int
    ) -> String {
        let lastTwoDigits = count % 100
        let lastDigit = count % 10

        if 11...14 ~= lastTwoDigits {
            return "\(count) задач"
        }

        switch lastDigit {
        case 1:
            return "\(count) задача"

        case 2...4:
            return "\(count) задачи"

        default:
            return "\(count) задач"
        }
    }
}

// MARK: - TaskListViewInput

extension TaskListViewController: TaskListViewInput {

    func display(
        tasks: [TaskListRowViewModel]
    ) {
        let previousTasksByID = tasksByID

        let previousIDs = Set(
            dataSource.snapshot().itemIdentifiers
        )

        let newTasksByID = tasks.reduce(into: [:]) {
            result,
            task in

            result[task.id] = task
        }

        tasksByID = newTasksByID

        let currentIDs = tasks.map(\.id)

        var snapshot =
            NSDiffableDataSourceSnapshot<Int, UUID>()

        snapshot.appendSections([0])
        snapshot.appendItems(currentIDs)

        let changedExistingIDs = currentIDs.filter {
            previousIDs.contains($0)
                && previousTasksByID[$0] != newTasksByID[$0]
        }

        snapshot.reconfigureItems(changedExistingIDs)

        dataSource.apply(
            snapshot,
            animatingDifferences: view.window != nil
        )

        taskCountLabel.text = makeTaskCountText(
            for: tasks.count
        )
    }

    func displayError(
        title: String,
        message: String
    ) {
        guard canPresentAlert else {
            return
        }

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Понятно",
                style: .default
            )
        )

        present(
            alert,
            animated: true
        )
    }

    func displayInitialLoadError(
        message: String
    ) {
        guard canPresentAlert else {
            return
        }

        let alert = UIAlertController(
            title:
                "Не удалось загрузить стартовые задачи",
            message:
                """
                \(message)

                Локальные задачи продолжат работать. \
                Можно повторить загрузку сейчас или позже.
                """,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Позже",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Повторить",
                style: .default
            ) { [weak self] _ in
                self?.presenter?
                    .didTapRetryInitialLoad()
            }
        )

        present(
            alert,
            animated: true
        )
    }
}

// MARK: - UITableViewDelegate

extension TaskListViewController:
    UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard
            let taskID =
                dataSource.itemIdentifier(
                    for: indexPath
                )
        else {
            return
        }

        searchTextField
            .resignFirstResponder()

        presenter?.didSelectTask(
            id: taskID
        )
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt
            indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let taskID =
                dataSource.itemIdentifier(
                    for: indexPath
                )
        else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: taskID as NSUUID,
            previewProvider: nil
        ) { [weak self] _ in
            guard let self else {
                return nil
            }

            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(
                    systemName: "square.and.pencil"
                )
            ) { [weak self] _ in
                self?.presenter?
                    .didRequestEditTask(
                        id: taskID
                    )
            }

            let shareAction = UIAction(
                title: "Поделиться",
                image: UIImage(
                    systemName:
                        "square.and.arrow.up"
                )
            ) { [weak self] _ in
                self?.presenter?
                    .didRequestShareTask(
                        id: taskID
                    )
            }

            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(
                    systemName: "trash"
                ),
                attributes: .destructive
            ) { [weak self] _ in
                self?.presenter?
                    .didRequestDeleteTask(
                        id: taskID
                    )
            }

            return UIMenu(
                children: [
                    editAction,
                    shareAction,
                    deleteAction
                ]
            )
        }
    }
}

// MARK: - UITextFieldDelegate

extension TaskListViewController: UITextFieldDelegate {

    func textFieldShouldReturn(
        _ textField: UITextField
    ) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
