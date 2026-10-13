//
//  ButtonSetViewController.swift
//  TJJupiterVMDemo
//
//  Created by leo.shin on 8/26/26.
//

import UIKit
import WebKit
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearCacheTapped)
        )

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
        TJJupiterVMAuth.shared.setServerConfig(region: .SAUDI, branch: .DEV)
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

    @objc private func clearCacheTapped() {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: "캐시 초기화", message: "앱의 모든 캐시(UserDefaults, 웹뷰 데이터, 디스크 캐시)를 삭제합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { [weak self] _ in
            self?.clearAllCaches()
        })
        present(alert, animated: true)
    }

    private func clearAllCaches() {
        // UserDefaults (데모 입력값 + SDK 리소스 캐시 메타데이터)
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        // 네트워크 캐시 / 쿠키
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }

        // 디스크 캐시 (Caches, Application Support, tmp)
        let fileManager = FileManager.default
        let directories = [
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
            fileManager.temporaryDirectory
        ].compactMap { $0 }
        for directory in directories {
            let contents = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            contents.forEach { try? fileManager.removeItem(at: $0) }
        }

        // 웹뷰 데이터
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { [weak self] in
            print("(ButtonSetViewController) clearAllCaches -> 완료")
            self?.presentCacheClearedAlert()
        }
    }

    private func presentCacheClearedAlert() {
        guard presentedViewController == nil else { return }

        // SDK 메모리 캐시는 프로세스가 살아있는 동안 유지되므로 재시작을 안내한다.
        let alert = UIAlertController(title: "캐시 초기화 완료", message: "메모리에 남은 캐시까지 비우려면 앱을 재시작하세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
