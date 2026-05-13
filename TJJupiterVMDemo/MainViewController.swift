
import UIKit
import CoreBluetooth
import CoreLocation
import CoreMotion
import TJJupiterVMSDK

class MainViewController: UIViewController, TJJupiterVMDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate {
    private let enabledButtonColor = UIColor(hex: "#E47325")
    private let pressedButtonColor = UIColor(hex: "#C95D17")
    private let loadingButtonColor = UIColor(hex: "#A64E17")
    private let disabledButtonColor = UIColor(hex: "#D3D7DC")
    private let disabledTitleColor = UIColor(hex: "#7E8792")
    private let panelBorderColor = UIColor(hex: "#E7DED3")
    private let frameIdleBorderColor = UIColor(hex: "#D6DCE3")
    private let frameActiveBorderColor = UIColor(hex: "#E47325")
    private let motionUsageKey = "NSMotionUsageDescription"
    private let locationWhenInUseUsageKey = "NSLocationWhenInUseUsageDescription"
    private let bluetoothUsageKey = "NSBluetoothAlwaysUsageDescription"
    private let bluetoothPeripheralUsageKey = "NSBluetoothPeripheralUsageDescription"

    private enum AuthState: Equatable {
        case idle
        case inProgress
        case succeeded
        case failed
    }

    private enum PermissionValidationIssue: Equatable {
        case missingPlistKeys([String])
        case motionDenied
        case motionRestricted
        case locationDenied
        case bluetoothDenied
    }

    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private var bluetoothManager: CBCentralManager?
    private var authState: AuthState = .idle
    private var hasRequiredPermissions = false
    private var hasInitializedMap = false
    private var isInitializingMap = false
    private var isFrameConfigured = false
    private var isConfiguringFrame = false
    private var isClosingFrame = false
    private var isServiceRunning = false
    private var isStoppingService = false
    private var isRequestingMotionPermission = false
    private var lastPresentedPermissionIssue: PermissionValidationIssue?

    func onInitSuccess(_ isSuccess: Bool, _ code: TJJupiterVMSDK.InitErrorCode?) {
        isInitializingMap = false

        if isSuccess {
            hasInitializedMap = true
            setVacantParkingLocations()
        } else {
            hasInitializedMap = false
        }

        refreshButtonAvailability()
    }
    
    func onJupiterSuccess(_ isSuccess: Bool, _ code: TJJupiterVMSDK.JupiterErrorCode?) {
        if !isSuccess {
            isServiceRunning = false
        }

        print("(MainViewController) onJupiterSuccess -> isSuccess: \(isSuccess), code: \(code)")
        refreshButtonAvailability()
    }
    
    func onJupiterResult(_ result: TJJupiterVMSDK.JupiterResult) {
        // TODO
    }
    
    func onWebViewSuccess(_ isSuccess: Bool, _ code: TJJupiterVMSDK.VMErrorCode?) {
        isConfiguringFrame = false

        if isSuccess {
            isFrameConfigured = true
            print("(MainViewController) onWebViewSuccess -> isSuccess: \(isSuccess), code: \(code)")
        } else {
            isFrameConfigured = false
        }

        refreshButtonAvailability()
    }
    
    func didWebViewRemoved() {
        isClosingFrame = false
        isConfiguringFrame = false
        isFrameConfigured = false
        removeSelectVehicleView()
        refreshButtonAvailability()
    }
    
    func isEnteringWardDeteced(info: TJJupiterVMSDK.EnteringInfo) {
        // TODO
    }
    
    func isParkingLocationTapped(_ parkingLocationId: String) {
        self.showSelectVehicleView(parkingLocationId: parkingLocationId)
    }
    
    
    private let vmView = TJJupiterVMView()
    private var selectVehicleView: SelectVehicleView?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hex: "#32404D")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let buttonPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FAF7F2")
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#E7DED3").cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let frameContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F4F6F8")
        view.layer.cornerRadius = 22
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(hex: "#D6DCE3").cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let framePlaceholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "#6B7680")
        label.text = "VM Frame Host\nconfigureFrame 버튼으로 연결"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var initializeButton = makeActionButton(title: "initialize")
    private lazy var configureFrameButton = makeActionButton(title: "configureFrame")
    private lazy var closeFrameButton = makeActionButton(title: "closeFrame")
    private lazy var startServiceButton = makeActionButton(title: "startService")
    private lazy var stopServiceButton = makeActionButton(title: "stopService")

    private let frameControlStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let serviceControlStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let groupedControlStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    @objc private func initializeTapped() {
        isInitializingMap = true
        refreshButtonAvailability()
        initVMView()
    }
    
    @objc private func configureFrameTapped() {
        isConfiguringFrame = true
        refreshButtonAvailability()
        configureVMView()
    }
    
    @objc private func closeFrameTapped() {
        isClosingFrame = true
        refreshButtonAvailability()
        closeVMView()
    }
    
    @objc private func startServiceTapped() {
        isServiceRunning = true
        refreshButtonAvailability()
        startService()
    }

    @objc private func stopServiceTapped() {
        isStoppingService = true
        refreshButtonAvailability()
        stopService()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configurePermissionManagers()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        evaluateLaunchRequirements()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        title = "TJJupiterVM Demo"
        
        view.addSubview(statusLabel)
        view.addSubview(buttonPanelView)
        view.addSubview(frameContainerView)

        buttonPanelView.addSubview(buttonStackView)
        frameContainerView.addSubview(framePlaceholderLabel)

        buttonStackView.addArrangedSubview(initializeButton)
        buttonStackView.addArrangedSubview(groupedControlStackView)

        frameControlStackView.addArrangedSubview(configureFrameButton)
        frameControlStackView.addArrangedSubview(closeFrameButton)

        serviceControlStackView.addArrangedSubview(startServiceButton)
        serviceControlStackView.addArrangedSubview(stopServiceButton)

        groupedControlStackView.addArrangedSubview(frameControlStackView)
        groupedControlStackView.addArrangedSubview(serviceControlStackView)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buttonPanelView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 14),
            buttonPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStackView.topAnchor.constraint(equalTo: buttonPanelView.topAnchor, constant: 16),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonPanelView.bottomAnchor, constant: -16),
            buttonStackView.leadingAnchor.constraint(equalTo: buttonPanelView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonPanelView.trailingAnchor, constant: -16),

            frameContainerView.topAnchor.constraint(equalTo: buttonPanelView.bottomAnchor, constant: 18),
            frameContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            frameContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            frameContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            framePlaceholderLabel.centerXAnchor.constraint(equalTo: frameContainerView.centerXAnchor),
            framePlaceholderLabel.centerYAnchor.constraint(equalTo: frameContainerView.centerYAnchor),
            framePlaceholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: frameContainerView.leadingAnchor, constant: 24),
            framePlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: frameContainerView.trailingAnchor, constant: -24),

            initializeButton.heightAnchor.constraint(equalToConstant: 48),
            configureFrameButton.heightAnchor.constraint(equalToConstant: 48),
            closeFrameButton.heightAnchor.constraint(equalToConstant: 48),
            startServiceButton.heightAnchor.constraint(equalToConstant: 48),
            stopServiceButton.heightAnchor.constraint(equalToConstant: 48),
            groupedControlStackView.heightAnchor.constraint(equalToConstant: 108)
        ])

        bindButtonActions()
        refreshButtonAvailability()
    }

    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.backgroundColor = enabledButtonColor
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.isEnabled = false
        return button
    }

    private func bindButtonActions() {
        initializeButton.addTarget(self, action: #selector(initializeTapped), for: .touchUpInside)
        configureFrameButton.addTarget(self, action: #selector(configureFrameTapped), for: .touchUpInside)
        closeFrameButton.addTarget(self, action: #selector(closeFrameTapped), for: .touchUpInside)
        startServiceButton.addTarget(self, action: #selector(startServiceTapped), for: .touchUpInside)
        stopServiceButton.addTarget(self, action: #selector(stopServiceTapped), for: .touchUpInside)

        [
            initializeButton,
            configureFrameButton,
            closeFrameButton,
            startServiceButton,
            stopServiceButton
        ].forEach { button in
            button.addTarget(self, action: #selector(handleButtonPressDown(_:)), for: [.touchDown, .touchDragEnter])
            button.addTarget(self, action: #selector(handleButtonPressUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        }
    }

    private func updateActionButton(_ button: UIButton, title: String, isEnabled: Bool, isLoading: Bool = false) {
        button.isEnabled = isEnabled
        button.setTitle(isLoading ? "\(title)..." : title, for: .normal)
        button.backgroundColor = isLoading ? loadingButtonColor : (isEnabled ? enabledButtonColor : disabledButtonColor)
        button.setTitleColor(isEnabled || isLoading ? .white : disabledTitleColor, for: .normal)
        button.transform = .identity
        button.alpha = isEnabled || isLoading ? 1.0 : 0.72
        button.layer.shadowOpacity = isEnabled || isLoading ? 0.16 : 0.0
        button.layer.borderColor = (isEnabled || isLoading ? enabledButtonColor : panelBorderColor).cgColor
    }

    @objc private func handleButtonPressDown(_ sender: UIButton) {
        guard sender.isEnabled else { return }

        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseOut]) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.backgroundColor = self.pressedButtonColor
        }
    }

    @objc private func handleButtonPressUp(_ sender: UIButton) {
        let targetColor: UIColor
        if sender === initializeButton && isInitializingMap {
            targetColor = loadingButtonColor
        } else if sender === configureFrameButton && isConfiguringFrame {
            targetColor = loadingButtonColor
        } else if sender === closeFrameButton && isClosingFrame {
            targetColor = loadingButtonColor
        } else if sender === stopServiceButton && isStoppingService {
            targetColor = loadingButtonColor
        } else {
            targetColor = sender.isEnabled ? enabledButtonColor : disabledButtonColor
        }

        UIView.animate(withDuration: 0.18,
                       delay: 0,
                       usingSpringWithDamping: 0.72,
                       initialSpringVelocity: 0.5,
                       options: [.beginFromCurrentState, .curveEaseOut]) {
            sender.transform = .identity
            sender.backgroundColor = targetColor
        }
    }

    private func configurePermissionManagers() {
        locationManager.delegate = self
    }

    private func logPermissionSnapshot(context: String) {
        let motionAvailable = CMMotionActivityManager.isActivityAvailable()
        let motionStatus = describeMotionAuthorizationStatus(CMMotionActivityManager.authorizationStatus())
        let locationStatus = describeLocationAuthorizationStatus(locationManager.authorizationStatus)
        let bluetoothAuthorization = describeBluetoothAuthorizationStatus(CBCentralManager.authorization)
        let bluetoothState = bluetoothManager.map { describeBluetoothManagerState($0.state) } ?? "uninitialized"

        print("""
        [Permissions][\(context)] \
        motionAvailable=\(motionAvailable) \
        motionStatus=\(motionStatus) \
        locationStatus=\(locationStatus) \
        bluetoothAuthorization=\(bluetoothAuthorization) \
        bluetoothState=\(bluetoothState) \
        hasRequiredPermissions=\(hasRequiredPermissions) \
        authState=\(String(describing: authState)) \
        isRequestingMotionPermission=\(isRequestingMotionPermission)
        """)
    }

    private func describeMotionAuthorizationStatus(_ status: CMAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "authorized"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        @unknown default:
            return "unknown(\(status.rawValue))"
        }
    }

    private func describeLocationAuthorizationStatus(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func describeBluetoothAuthorizationStatus(_ status: CBManagerAuthorization) -> String {
        switch status {
        case .allowedAlways:
            return "allowedAlways"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }

    private func describeBluetoothManagerState(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            return "unknown"
        case .resetting:
            return "resetting"
        case .unsupported:
            return "unsupported"
        case .unauthorized:
            return "unauthorized"
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        @unknown default:
            return "unknown"
        }
    }

    @objc private func handleAppWillEnterForeground() {
        evaluateLaunchRequirements()
    }

    private func evaluateLaunchRequirements() {
        logPermissionSnapshot(context: "evaluateLaunchRequirements:start")

        let missingKeys = missingRequiredUsageDescriptionKeys()
        if !missingKeys.isEmpty {
            hasRequiredPermissions = false
            refreshButtonAvailability()
            print("[Permissions][evaluateLaunchRequirements] missingPlistKeys=\(missingKeys)")
            presentPermissionIssueIfNeeded(.missingPlistKeys(missingKeys))
            return
        }

        let permissionState = evaluatePermissions()
        hasRequiredPermissions = permissionState.allGranted
        refreshButtonAvailability()
        print("[Permissions][evaluateLaunchRequirements] allGranted=\(permissionState.allGranted) isPending=\(permissionState.isPending) issue=\(String(describing: permissionState.issue))")
        logPermissionSnapshot(context: "evaluateLaunchRequirements:afterEvaluation")

        if let issue = permissionState.issue {
            presentPermissionIssueIfNeeded(issue)
            return
        }

        if permissionState.isPending {
            return
        }

        lastPresentedPermissionIssue = nil
        ensureAuthIfNeeded()
    }

    private func ensureAuthIfNeeded() {
        guard hasRequiredPermissions else { return }

        switch authState {
        case .idle, .failed:
            doAuth()
        case .inProgress, .succeeded:
            refreshButtonAvailability()
        }
    }

    private func refreshButtonAvailability() {
        let isReadyAfterInitialize = hasRequiredPermissions
            && authState == .succeeded
            && hasInitializedMap
        let canInit = hasRequiredPermissions
            && authState == .succeeded
            && !isInitializingMap
            && !hasInitializedMap
        let canConfigureFrame = isReadyAfterInitialize
            && !isFrameConfigured
            && !isConfiguringFrame
            && !isClosingFrame
        let canCloseFrame = isReadyAfterInitialize
            && isFrameConfigured
            && !isConfiguringFrame
            && !isClosingFrame
        let canStartService = isReadyAfterInitialize
            && !isServiceRunning
            && !isStoppingService
        let canStopService = isReadyAfterInitialize
            && isServiceRunning
            && !isStoppingService

        updateActionButton(initializeButton, title: "initialize", isEnabled: canInit, isLoading: isInitializingMap)
        updateActionButton(configureFrameButton, title: "configureFrame", isEnabled: canConfigureFrame, isLoading: isConfiguringFrame)
        updateActionButton(closeFrameButton, title: "closeFrame", isEnabled: canCloseFrame, isLoading: isClosingFrame)
        updateActionButton(startServiceButton, title: "startService", isEnabled: canStartService)
        updateActionButton(stopServiceButton, title: "stopService", isEnabled: canStopService, isLoading: isStoppingService)
        updateStatusDisplay()
    }

    private func updateStatusDisplay() {
        let permissionText = hasRequiredPermissions ? "권한 준비됨" : "권한 대기"
        let authText: String
        switch authState {
        case .idle:
            authText = "인증 대기"
        case .inProgress:
            authText = "인증 중"
        case .succeeded:
            authText = "인증 완료"
        case .failed:
            authText = "인증 실패"
        }

        let initializeText = isInitializingMap ? "초기화 중" : (hasInitializedMap ? "초기화 완료" : "초기화 전")
        let frameText: String
        if isClosingFrame {
            frameText = "프레임 해제 중"
        } else if isConfiguringFrame {
            frameText = "프레임 연결 중"
        } else if isFrameConfigured {
            frameText = "프레임 연결됨"
        } else {
            frameText = "프레임 미연결"
        }

        let serviceText: String
        if isStoppingService {
            serviceText = "서비스 중지 중"
        } else if isServiceRunning {
            serviceText = "서비스 실행 중"
        } else {
            serviceText = "서비스 중지됨"
        }

        statusLabel.text = "\(permissionText)  |  \(authText)\n\(initializeText)  |  \(frameText)  |  \(serviceText)"
        frameContainerView.layer.borderColor = (isFrameConfigured || isConfiguringFrame ? frameActiveBorderColor : frameIdleBorderColor).cgColor
        framePlaceholderLabel.isHidden = isFrameConfigured || isConfiguringFrame
    }

    private func missingRequiredUsageDescriptionKeys() -> [String] {
        var missingKeys: [String] = []

        if requiresMotionPermission,
           infoDictionaryString(forKey: motionUsageKey) == nil {
            missingKeys.append(motionUsageKey)
        }

        if requiresLocationPermission {
            if infoDictionaryString(forKey: locationWhenInUseUsageKey) == nil {
                missingKeys.append(locationWhenInUseUsageKey)
            }
        }

        if requiresBluetoothPermission {
            if infoDictionaryString(forKey: bluetoothUsageKey) == nil {
                missingKeys.append(bluetoothUsageKey)
            }

            if infoDictionaryString(forKey: bluetoothPeripheralUsageKey) == nil {
                missingKeys.append(bluetoothPeripheralUsageKey)
            }
        }

        return missingKeys
    }

    private var requiresMotionPermission: Bool {
        true
    }

    private var requiresLocationPermission: Bool {
        true
    }

    private var requiresBluetoothPermission: Bool {
        true
    }

    private func infoDictionaryString(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func evaluatePermissions() -> (allGranted: Bool, isPending: Bool, issue: PermissionValidationIssue?) {
        let motionPermission = evaluateMotionPermission()
        if case .denied = motionPermission {
            let issue: PermissionValidationIssue
            switch CMMotionActivityManager.authorizationStatus() {
            case .restricted:
                issue = .motionRestricted
            case .denied:
                issue = .motionDenied
            case .authorized, .notDetermined:
                issue = .motionDenied
            @unknown default:
                issue = .motionDenied
            }
            return (false, false, issue)
        }

        if motionPermission == .pending {
            return (false, true, nil)
        }

        let locationPermission = evaluateLocationPermission()
        if case .denied = locationPermission {
            return (false, false, .locationDenied)
        }

        if locationPermission == .pending {
            return (false, true, nil)
        }

        let bluetoothPermission = evaluateBluetoothPermission()
        if case .denied = bluetoothPermission {
            return (false, false, .bluetoothDenied)
        }

        let allGranted = motionPermission == .granted
            && locationPermission == .granted
            && bluetoothPermission == .granted
        let isPending = bluetoothPermission == .pending
        return (allGranted, isPending, nil)
    }

    private enum PermissionState: Equatable {
        case granted
        case pending
        case denied
    }

    private func evaluateMotionPermission() -> PermissionState {
        guard requiresMotionPermission else { return .granted }

        guard CMMotionActivityManager.isActivityAvailable() else {
            return .granted
        }

        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            return .granted
        case .notDetermined:
            requestMotionPermissionIfNeeded()
            return .pending
        case .restricted, .denied:
            return .denied
        @unknown default:
            return .pending
        }
    }

    private func evaluateLocationPermission() -> PermissionState {
        guard requiresLocationPermission else { return .granted }

        let authorizationStatus = locationManager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways:
            return .granted
        case .authorizedWhenInUse:
            return .granted
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return .pending
        case .restricted, .denied:
            return .denied
        @unknown default:
            return .pending
        }
    }

    private func evaluateBluetoothPermission() -> PermissionState {
        guard requiresBluetoothPermission else { return .granted }

        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(delegate: self,
                                                queue: .main,
                                                options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }

        switch CBCentralManager.authorization {
        case .allowedAlways:
            return .granted
        case .notDetermined:
            return .pending
        case .restricted, .denied:
            return .denied
        @unknown default:
            return .pending
        }
    }

    private func requestMotionPermissionIfNeeded() {
        guard !isRequestingMotionPermission else { return }
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        isRequestingMotionPermission = true
        logPermissionSnapshot(context: "requestMotionPermissionIfNeeded:beforeQuery")

        let now = Date()
        let startDate = now.addingTimeInterval(-60)

        motionActivityManager.queryActivityStarting(from: startDate, to: now, to: .main) { [weak self] _, _ in
            guard let self else { return }
            self.isRequestingMotionPermission = false
            self.logPermissionSnapshot(context: "requestMotionPermissionIfNeeded:completion")
            self.evaluateLaunchRequirements()
        }
    }

    private func presentPermissionIssueIfNeeded(_ issue: PermissionValidationIssue) {
        guard presentedViewController == nil else { return }
        guard issue != lastPresentedPermissionIssue else { return }

        lastPresentedPermissionIssue = issue

        let title: String
        let message: String

        switch issue {
        case .missingPlistKeys(let keys):
            title = "권한 설정 필요"
            message = "Info.plist에 필요한 권한 설명이 없습니다.\n\(keys.joined(separator: "\n"))"
        case .motionDenied:
            title = "모션 권한 필요"
            message = "실내지도 기능을 사용하려면 모션 및 피트니스 권한을 허용해야 합니다. 설정에서 권한을 허용해 주세요."
        case .motionRestricted:
            title = "모션 사용 제한됨"
            message = "이 기기에서는 모션 및 피트니스 접근이 제한되어 있습니다. 앱 설정에서 켜는 문제가 아니라 기기의 개인정보 보호 설정, 스크린 타임 제한, 또는 관리 정책(MDM) 때문에 막힌 상태일 수 있습니다."
        case .locationDenied:
            title = "위치 권한 필요"
            message = "실내지도 기능을 사용하려면 위치 권한을 허용해야 합니다. 설정에서 위치 권한을 허용해 주세요."
        case .bluetoothDenied:
            title = "블루투스 권한 필요"
            message = "실내지도 기능을 사용하려면 블루투스 권한을 허용해야 합니다. 설정에서 블루투스 권한을 허용해 주세요."
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))

        switch issue {
        case .motionDenied, .locationDenied, .bluetoothDenied:
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                self.openAppSettings()
            })
        case .missingPlistKeys, .motionRestricted:
            break
        }

        present(alert, animated: true)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logPermissionSnapshot(context: "locationManagerDidChangeAuthorization")
        evaluateLaunchRequirements()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logPermissionSnapshot(context: "centralManagerDidUpdateState")
        evaluateLaunchRequirements()
    }
    
    func doAuth() {
        authState = .inProgress
        refreshButtonAvailability()

        TJJupiterVMAuth.shared.auth(accessKey: "", secretAccessKey: "", completion: { [weak self] statusCode, success in
            guard let self else { return }
            let successRange = 200..<300
            self.authState = success && successRange.contains(statusCode) ? .succeeded : .failed
            self.refreshButtonAvailability()
        })
    }
    
    func initVMView() {
        vmView.delegate = self
        vmView.initialize(userId: "vm-test", sectorId: 20)
    }
    
    func configureVMView() {
        vmView.configureFrame(to: self.frameContainerView)
    }

    func closeVMView() {
        vmView.closeFrame()
    }
    
    func startService() {
        vmView.setSimulationMode(flag: true, rfdFileName: "sample_rfd.json", uvdFileName: "sample_uvd.json", eventFileName: "sample_event.json")
        vmView.startService()
    }

    func stopService() {
        vmView.stopService { [weak self] isSuccess, message in
            guard let self else { return }

            self.isStoppingService = false
            if isSuccess {
                self.isServiceRunning = false
            }

            print("(MainViewController) stopService -> isSuccess: \(isSuccess), message: \(message)")
            self.refreshButtonAvailability()
        }
    }
    
    func setVacantParkingLocations() {
        let idList = ["OB-1h82101id68tx3548", "OB-1h7zbmxfa10z93809", "OB-1h84se62jidlw3811"]
        var states = [String: ParkingLocationState]()
        for id in idList {
            states[id] = .VACANT
        }
        
        vmView.setVacantParkingLocations(levelId: 52, parkingLocationStates: states)
    }
        
    func showSelectVehicleView(parkingLocationId: String) {
        removeSelectVehicleView()

        let selectVehicleView = SelectVehicleView(parkingLocationId: parkingLocationId)
        selectVehicleView.translatesAutoresizingMaskIntoConstraints = false

        selectVehicleView.onTapOK = { [weak self] in
            print("(MainViewController) SelectVehicleView OK tapped")
            self?.vmView.setSavedParkingLocations(parkingLocationIds: [parkingLocationId])
            self?.selectVehicleView?.removeFromSuperview()
            self?.selectVehicleView = nil
        }

        selectVehicleView.onTapClose = { [weak self] in
            print("(MainViewController) SelectVehicleView closed")
            self?.vmView.setSavedParkingLocations(parkingLocationIds: [])
            self?.selectVehicleView?.removeFromSuperview()
            self?.selectVehicleView = nil
        }

        view.addSubview(selectVehicleView)
        NSLayoutConstraint.activate([
            selectVehicleView.topAnchor.constraint(equalTo: view.topAnchor),
            selectVehicleView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            selectVehicleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectVehicleView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.selectVehicleView = selectVehicleView
    }

    private func removeSelectVehicleView() {
        if let existingView = selectVehicleView {
            existingView.removeFromSuperview()
            selectVehicleView = nil
        }
    }
}
