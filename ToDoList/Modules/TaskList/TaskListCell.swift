import UIKit

final class TaskListCell: UITableViewCell {

    static let reuseIdentifier = "TaskListCell"

    var onCompletionTapped: ((Bool) -> Void)?

    private var viewModel: TaskListRowViewModel?

    private let completionButton: UIButton = {
        let button = UIButton(type: .system)

        let configuration = UIImage.SymbolConfiguration(
            pointSize: 24,
            weight: .regular
        )

        button.setPreferredSymbolConfiguration(
            configuration,
            forImageIn: .normal
        )

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.font = .systemFont(
            ofSize: 16,
            weight: .medium
        )

        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail

        return label
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()

        label.font = .systemFont(
            ofSize: 12,
            weight: .regular
        )

        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail

        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()

        label.font = .systemFont(
            ofSize: 12,
            weight: .regular
        )

        label.textColor = .secondaryLabel
        label.numberOfLines = 1

        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                detailsLabel,
                dateLabel
            ]
        )

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        configureCell()
        configureHierarchy()
        configureConstraints()
        configureActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureCell()
        configureHierarchy()
        configureConstraints()
        configureActions()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
        onCompletionTapped = nil

        titleLabel.attributedText = nil
        detailsLabel.text = nil
        dateLabel.text = nil
        completionButton.setImage(nil, for: .normal)
    }

    func configure(
        with viewModel: TaskListRowViewModel
    ) {
        self.viewModel = viewModel

        configureTitle(using: viewModel)

        detailsLabel.text = viewModel.details
        detailsLabel.isHidden = viewModel.details
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        dateLabel.text = viewModel.dateText

        let imageName = viewModel.isCompleted
            ? "checkmark.circle"
            : "circle"

        completionButton.setImage(
            UIImage(systemName: imageName),
            for: .normal
        )

        completionButton.tintColor = viewModel.isCompleted
            ? .systemYellow
            : .secondaryLabel

        completionButton.accessibilityLabel =
            viewModel.isCompleted
                ? "Отметить задачу невыполненной"
                : "Отметить задачу выполненной"

        completionButton.accessibilityValue =
            viewModel.isCompleted
                ? "Выполнено"
                : "Не выполнено"
    }

    private func configureTitle(
        using viewModel: TaskListRowViewModel
    ) {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: viewModel.isCompleted
                ? UIColor.secondaryLabel
                : UIColor.white
        ]

        if viewModel.isCompleted {
            attributes[.strikethroughStyle] =
                NSUnderlineStyle.single.rawValue
        }

        titleLabel.attributedText = NSAttributedString(
            string: viewModel.title,
            attributes: attributes
        )
    }

    private func configureCell() {
        backgroundColor = .black
        contentView.backgroundColor = .black

        selectionStyle = .none
        separatorInset = .zero
    }

    private func configureHierarchy() {
        contentView.addSubview(completionButton)
        contentView.addSubview(textStackView)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            completionButton.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: -10
            ),

            completionButton.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),

            completionButton.widthAnchor.constraint(
                equalToConstant: 44
            ),

            completionButton.heightAnchor.constraint(
                equalToConstant: 44
            ),

            textStackView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),

            textStackView.leadingAnchor.constraint(
                equalTo: completionButton.trailingAnchor,
                constant: -2
            ),

            textStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            textStackView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -12
            )
        ])
    }

    private func configureActions() {
        completionButton.addTarget(
            self,
            action: #selector(completionButtonTapped),
            for: .touchUpInside
        )
    }

    @objc
    private func completionButtonTapped() {
        guard let currentViewModel = viewModel else {
            return
        }

        let updatedViewModel =
            currentViewModel.settingCompletion(
                to: !currentViewModel.isCompleted
            )

        configure(with: updatedViewModel)

        onCompletionTapped?(
            updatedViewModel.isCompleted
        )
    }
}
