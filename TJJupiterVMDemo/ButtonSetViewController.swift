//
//  ButtonSetViewController.swift
//  TJJupiterVMDemo
//
//  Created by leo.shin on 8/26/26.
//

import UIKit
import TJJupiterVMSDK

class ButtonSetViewController: UIViewController {

    private let enabledButtonColor = UIColor(hex: "#E47325")
    private let disabledButtonColor = UIColor(hex: "#D3D7DC")
    private let disabledTitleColor = UIColor(hex: "#7E8792")

    private enum AuthState: Equatable {
        case idle
        case inProgress
        case succeeded
        case failed
    }

    private var authState: AuthState = .idle
    private var authStartTime: CFAbsoluteTime?

    private lazy var singleSectorButton = makeModeButton(title: "단일 섹터", action: #selector(singleSectorTapped))
    private lazy var multiSectorButton = makeModeButton(title: "다중 섹터", action: #selector(multiSectorTapped))

    private lazy var modeButtonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [singleSectorButton, multiSectorButton])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let authStatusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hex: "#32404D")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "TJJupiterVM Demo"

        view.addSubview(modeButtonStackView)
        view.addSubview(authStatusLabel)

        NSLayoutConstraint.activate([
            modeButtonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeButtonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            modeButtonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            modeButtonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            modeButtonStackView.heightAnchor.constraint(equalToConstant: 56),

            authStatusLabel.topAnchor.constraint(equalTo: modeButtonStackView.bottomAnchor, constant: 16),
            authStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            authStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        refreshAuthDisplay()
        doAuth()
    }

    private func makeModeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.isEnabled = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func refreshAuthDisplay() {
        let isEnabled = authState == .succeeded
        [singleSectorButton, multiSectorButton].forEach { button in
            button.isEnabled = isEnabled
            button.backgroundColor = isEnabled ? enabledButtonColor : disabledButtonColor
            button.setTitleColor(isEnabled ? .white : disabledTitleColor, for: .normal)
            button.alpha = isEnabled ? 1.0 : 0.72
            button.layer.shadowOpacity = isEnabled ? 0.16 : 0.0
        }

        switch authState {
        case .idle:
            authStatusLabel.text = "인증 대기"
        case .inProgress:
            authStatusLabel.text = "인증 중..."
        case .succeeded:
            authStatusLabel.text = "인증 완료"
        case .failed:
            authStatusLabel.text = "인증 실패"
        }
    }

    private func doAuth() {
        authState = .inProgress
        refreshAuthDisplay()
        TJJupiterVMAuth.shared.setServerConfig(region: .KOREA, branch: .DEV)
        authStartTime = CFAbsoluteTimeGetCurrent()
        print("(ButtonSetViewController) [TIMING] auth -> 시작")
        TJJupiterVMAuth.shared.auth(accessKey: "", secretAccessKey: "", completion: { [weak self] statusCode, success in
            DispatchQueue.main.async {
                guard let self else { return }
                if let start = self.authStartTime {
                    let elapsed = CFAbsoluteTimeGetCurrent() - start
                    print(String(format: "(ButtonSetViewController) [TIMING] auth -> 종료, 경과: %.3f초", elapsed))
                    self.authStartTime = nil
                }
                let successRange = 200..<300
                self.authState = success && successRange.contains(statusCode) ? .succeeded : .failed
                self.refreshAuthDisplay()

                if self.authState == .failed {
                    self.presentAuthFailedAlert(statusCode: statusCode)
                }
            }
        })
    }

    private func presentAuthFailedAlert(statusCode: Int) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: "인증 실패", message: "statusCode: \(statusCode)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "재시도", style: .default) { [weak self] _ in
            self?.doAuth()
        })
        present(alert, animated: true)
    }

    @objc private func singleSectorTapped() {
        pushMainViewController(sectorMode: .single)
    }

    @objc private func multiSectorTapped() {
        pushMainViewController(sectorMode: .multi)
    }

    private func pushMainViewController(sectorMode: MainViewController.SectorMode) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController else { return }
        mainVC.sectorMode = sectorMode
        navigationController?.pushViewController(mainVC, animated: true)
    }
}
