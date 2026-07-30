import UIKit

final class TaskEditorViewController:
    UIViewController {

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let contentTopInset: CGFloat = 8
        static let titleHeight: CGFloat = 48
        static let titleToDateSpacing: CGFloat = 2
        static let dateToDetailsSpacing: CGFloat = 14
        static let keyboardSpacing: CGFloat = 12
    }

    private enum Limits {
        static let maximumTitleLength = 200
        static let maximumDetailsLength = 4_000
    }

    var presenter: TaskEditorViewOutput?

    private var shouldFocusTitle = false
    private var isSaving = false

    private let titleTextField: UITextField = {
        let textField = UITextField()

        textField.textColor = .white
        textField.tintColor = .systemYellow

        textField.font = .systemFont(
            ofSize: 34,
            weight: .bold
        )

        textField.attributedPlaceholder =
            NSAttributedString(
                string: "Название",
                attributes: [
                    .foregroundColor:
                        UIColor.secondaryLabel
                ]
            )

        textField.returnKeyType = .next
        textField.clearButtonMode = .never
        textField.autocorrectionType = .yes
        textField.autocapitalizationType =
            .sentences

        textField.accessibilityLabel =
            "Название задачи"

        textField.translatesAutoresizingMaskIntoConstraints =
            false

        return textField
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()

        label.textColor = .secondaryLabel

        label.font = .systemFont(
            ofSize: 12,
            weight: .regular
        )

        label.accessibilityLabel =
            "Дата создания задачи"

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    private let detailsTextView: UITextView = {
        let textView = UITextView()

        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = .systemYellow

        textView.font = .systemFont(
            ofSize: 17,
            weight: .regular
        )

        textView.textContainerInset =
            UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: 12,
                right: 0
            )

        textView.textContainer
            .lineFragmentPadding = 0

        textView.autocorrectionType = .yes
        textView.autocapitalizationType =
            .sentences

        textView.keyboardDismissMode =
            .interactive

        textView.accessibilityLabel =
            "Описание задачи"

        textView.translatesAutoresizingMaskIntoConstraints =
            false

        return textView
    }()

    private let detailsPlaceholderLabel:
        UILabel = {

        let label = UILabel()

        label.text = "Описание"
        label.textColor = .secondaryLabel

        label.font = .systemFont(
            ofSize: 17,
            weight: .regular
        )

        label.translatesAutoresizingMaskIntoConstraints =
            false

        return label
    }()

    private let activityIndicator:
        UIActivityIndicatorView = {

        let indicator =
            UIActivityIndicatorView(
                style: .medium
            )

        indicator.color = .systemYellow
        indicator.hidesWhenStopped = true

        indicator.translatesAutoresizingMaskIntoConstraints =
            false

        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureNavigation()
        configureHierarchy()
        configureConstraints()
        configureActions()

        guard let presenter else {
            assertionFailure(
                "TaskEditorPresenter is not configured"
            )
            return
        }

        presenter.viewDidLoad()
    }

    override func viewDidAppear(
        _ animated: Bool
    ) {
        super.viewDidAppear(animated)

        if shouldFocusTitle {
            shouldFocusTitle = false
            titleTextField.becomeFirstResponder()
        }
    }

    override func viewWillAppear(
        _ animated: Bool
    ) {
        super.viewWillAppear(animated)

        navigationController?
            .setNavigationBarHidden(
                false,
                animated: animated
            )

        navigationController?
            .interactivePopGestureRecognizer?
            .isEnabled = false
    }

    override func viewWillDisappear(
        _ animated: Bool
    ) {
        super.viewWillDisappear(animated)

        navigationController?
            .interactivePopGestureRecognizer?
            .isEnabled = true
    }

    private func configureAppearance() {
        view.backgroundColor = .black
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true

        var buttonConfiguration =
            UIButton.Configuration.plain()

        buttonConfiguration.title = "Назад"
        buttonConfiguration.image =
            UIImage(
                systemName: "chevron.left"
            )

        buttonConfiguration.imagePadding = 3
        buttonConfiguration.baseForegroundColor =
            .systemYellow

        let backButton = UIButton(
            configuration:
                buttonConfiguration
        )

        backButton.addTarget(
            self,
            action: #selector(backButtonTapped),
            for: .touchUpInside
        )

        backButton.accessibilityLabel =
            "Сохранить и вернуться назад"

        navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                customView: backButton
            )

        let appearance =
            UINavigationBarAppearance()

        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear

        navigationController?
            .navigationBar
            .standardAppearance = appearance

        navigationController?
            .navigationBar
            .scrollEdgeAppearance = appearance

        navigationController?
            .navigationBar
            .compactAppearance = appearance
    }

    private func configureHierarchy() {
        view.addSubview(titleTextField)
        view.addSubview(dateLabel)
        view.addSubview(detailsTextView)
        view.addSubview(activityIndicator)

        detailsTextView.addSubview(
            detailsPlaceholderLabel
        )
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide
                        .topAnchor,
                constant:
                    Layout.contentTopInset
            ),

            titleTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant:
                    Layout.horizontalInset
            ),

            titleTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant:
                    -Layout.horizontalInset
            ),

            titleTextField.heightAnchor.constraint(
                equalToConstant:
                    Layout.titleHeight
            ),

            dateLabel.topAnchor.constraint(
                equalTo:
                    titleTextField
                        .bottomAnchor,
                constant:
                    Layout.titleToDateSpacing
            ),

            dateLabel.leadingAnchor.constraint(
                equalTo:
                    titleTextField
                        .leadingAnchor
            ),

            dateLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    titleTextField
                        .trailingAnchor
            ),

            detailsTextView.topAnchor.constraint(
                equalTo:
                    dateLabel.bottomAnchor,
                constant:
                    Layout.dateToDetailsSpacing
            ),

            detailsTextView.leadingAnchor.constraint(
                equalTo:
                    titleTextField
                        .leadingAnchor
            ),

            detailsTextView.trailingAnchor.constraint(
                equalTo:
                    titleTextField
                        .trailingAnchor
            ),

            detailsTextView.bottomAnchor.constraint(
                equalTo:
                    view.keyboardLayoutGuide
                        .topAnchor,
                constant:
                    -Layout.keyboardSpacing
            ),

            detailsPlaceholderLabel.topAnchor.constraint(
                equalTo:
                    detailsTextView
                        .topAnchor
            ),

            detailsPlaceholderLabel.leadingAnchor.constraint(
                equalTo:
                    detailsTextView
                        .leadingAnchor
            ),

            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    private func configureActions() {
        titleTextField.delegate = self
        detailsTextView.delegate = self

        titleTextField.addTarget(
            self,
            action:
                #selector(titleEditingDidEndOnExit),
            for: .editingDidEndOnExit
        )
    }

    @objc
    private func backButtonTapped() {
        guard !isSaving else {
            return
        }

        presenter?.didTapBack(
            title:
                titleTextField.text ?? "",
            details:
                detailsTextView.text ?? ""
        )
    }

    @objc
    private func titleEditingDidEndOnExit() {
        detailsTextView.becomeFirstResponder()
    }
}

extension TaskEditorViewController:
    TaskEditorViewInput {

    func display(
        viewModel: TaskEditorViewModel
    ) {
        titleTextField.text =
            viewModel.title

        detailsTextView.text =
            viewModel.details

        dateLabel.text =
            viewModel.dateText

        detailsPlaceholderLabel.isHidden =
            !viewModel.details.isEmpty

        shouldFocusTitle =
            viewModel.shouldFocusTitle
    }

    func setSaving(_ isSaving: Bool) {
        self.isSaving = isSaving

        titleTextField.isEnabled =
            !isSaving

        detailsTextView.isEditable =
            !isSaving

        navigationItem
            .leftBarButtonItem?
            .isEnabled = !isSaving

        navigationItem
            .leftBarButtonItem?
            .customView?
            .isUserInteractionEnabled = !isSaving

        navigationItem
            .leftBarButtonItem?
            .customView?
            .alpha = isSaving ? 0.5 : 1

        if isSaving {
            view.endEditing(true)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func displayError(message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Не удалось сохранить задачу",
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
}

extension TaskEditorViewController:
    UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard
            let currentText = textField.text,
            let textRange = Range(
                range,
                in: currentText
            )
        else {
            return false
        }

        let updatedText =
            currentText.replacingCharacters(
                in: textRange,
                with: string
            )

        return updatedText.count <=
            Limits.maximumTitleLength
    }
}

extension TaskEditorViewController:
    UITextViewDelegate {

    func textViewDidChange(
        _ textView: UITextView
    ) {
        detailsPlaceholderLabel.isHidden =
            !textView.text.isEmpty
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard
            let textRange = Range(
                range,
                in: textView.text
            )
        else {
            return false
        }

        let updatedText =
            textView.text
                .replacingCharacters(
                    in: textRange,
                    with: text
                )

        return updatedText.count <=
            Limits.maximumDetailsLength
    }
}
