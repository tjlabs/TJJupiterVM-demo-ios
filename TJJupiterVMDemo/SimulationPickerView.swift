import Foundation
import UIKit

struct SimulationFileSet: Equatable {
    let displayName: String
    let rfdFileName: String
    let uvdFileName: String
    let eventFileName: String
}

enum SimulationExportsDirectoryError: LocalizedError {
    case documentsDirectoryUnavailable
    case notDirectory(URL)

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            return "앱 Documents 디렉터리를 찾을 수 없습니다."
        case .notDirectory(let url):
            return "\(url.lastPathComponent) 경로가 폴더가 아닙니다."
        }
    }
}

enum SimulationExportsDirectory {
    static let folderName = "Exports"

    static func url(fileManager: FileManager = .default) throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw SimulationExportsDirectoryError.documentsDirectoryUnavailable
        }

        return documentsURL.appendingPathComponent(folderName, isDirectory: true)
    }

    @discardableResult
    static func ensureExists(fileManager: FileManager = .default) throws -> URL {
        let exportsURL = try url(fileManager: fileManager)
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: exportsURL.path, isDirectory: &isDirectory)

        if exists {
            guard isDirectory.boolValue else {
                throw SimulationExportsDirectoryError.notDirectory(exportsURL)
            }
            return exportsURL
        }

        try fileManager.createDirectory(at: exportsURL, withIntermediateDirectories: true, attributes: nil)
        return exportsURL
    }

    static func availableFileSets(fileManager: FileManager = .default) throws -> [SimulationFileSet] {
        let exportsURL = try ensureExists(fileManager: fileManager)
        let fileURLs = try fileManager.contentsOfDirectory(
            at: exportsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        let suffixes: [(suffix: String, key: String)] = [
            ("_rfd.json", "rfd"),
            ("_uvd.json", "uvd"),
            ("_event.json", "event")
        ]

        var groupedFiles: [String: [String: String]] = [:]

        for fileURL in fileURLs {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }

            let fileName = fileURL.lastPathComponent
            let lowercasedName = fileName.lowercased()

            guard let match = suffixes.first(where: { lowercasedName.hasSuffix($0.suffix) }) else {
                continue
            }

            let baseName = String(fileName.dropLast(match.suffix.count))
            groupedFiles[baseName, default: [:]][match.key] = fileName
        }

        return groupedFiles.compactMap { baseName, files in
            guard
                let rfdFileName = files["rfd"],
                let uvdFileName = files["uvd"],
                let eventFileName = files["event"]
            else {
                return nil
            }

            let displayName = baseName.isEmpty ? rfdFileName.replacingOccurrences(of: "_rfd.json", with: "") : baseName

            return SimulationFileSet(
                displayName: displayName,
                rfdFileName: rfdFileName,
                uvdFileName: uvdFileName,
                eventFileName: eventFileName
            )
        }
        .sorted { lhs, rhs in
            lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }
}

private final class SimulationFileCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(with fileSet: SimulationFileSet, isSelected: Bool) {
        titleLabel.text = fileSet.displayName
        detailLabel.text = "\(fileSet.rfdFileName)\n\(fileSet.uvdFileName) / \(fileSet.eventFileName)"
        accessoryType = isSelected ? .checkmark : .none
    }

    private func setupView() {
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(detailLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}

final class SimulationFilePickerView: UIView {
    var onCancel: (() -> Void)?
    var onConfirm: ((SimulationFileSet) -> Void)?

    private var fileSets: [SimulationFileSet] = []
    private var selectedFileSet: SimulationFileSet?

    private let dimmedButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        return button
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "시뮬레이션 파일 선택"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Files 앱에서 접근 가능한 Exports 폴더의 *_rfd.json / *_uvd.json / *_event.json 세트만 표시됩니다."
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let contentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "선택 가능한 시뮬레이션 파일 세트가 없습니다."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.rowHeight = 84
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let cancelButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "취소"
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = .secondarySystemFill
        configuration.baseForegroundColor = .label

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = configuration
        return button
    }()

    private let confirmButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "확인"
        configuration.cornerStyle = .large

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = configuration
        button.isEnabled = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        bind()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        bind()
    }

    func configure(fileSets: [SimulationFileSet], selectedFileSet: SimulationFileSet?) {
        self.fileSets = fileSets
        self.selectedFileSet = selectedFileSet.flatMap { selectedFileSet in
            fileSets.first(where: { $0 == selectedFileSet })
        }

        emptyLabel.isHidden = !fileSets.isEmpty
        tableView.isHidden = fileSets.isEmpty
        confirmButton.isEnabled = self.selectedFileSet != nil
        tableView.reloadData()
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(dimmedButton)
        addSubview(containerView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(contentContainerView)
        containerView.addSubview(buttonStackView)

        contentContainerView.addSubview(tableView)
        contentContainerView.addSubview(emptyLabel)

        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SimulationFileCell.self, forCellReuseIdentifier: "SimulationFileCell")

        NSLayoutConstraint.activate([
            dimmedButton.topAnchor.constraint(equalTo: topAnchor),
            dimmedButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimmedButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmedButton.trailingAnchor.constraint(equalTo: trailingAnchor),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor, constant: 24),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            contentContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainerView.heightAnchor.constraint(equalToConstant: 320),

            tableView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: contentContainerView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -24),

            buttonStackView.topAnchor.constraint(equalTo: contentContainerView.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func bind() {
        dimmedButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)
    }

    @objc
    private func handleCancel() {
        onCancel?()
    }

    @objc
    private func handleConfirm() {
        guard let selectedFileSet else { return }
        onConfirm?(selectedFileSet)
    }
}

extension SimulationFilePickerView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fileSets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SimulationFileCell", for: indexPath) as? SimulationFileCell else {
            return UITableViewCell()
        }

        let fileSet = fileSets[indexPath.row]
        cell.configure(with: fileSet, isSelected: fileSet == selectedFileSet)
        return cell
    }
}

extension SimulationFilePickerView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedFileSet = fileSets[indexPath.row]
        confirmButton.isEnabled = true
        tableView.reloadData()
    }
}
