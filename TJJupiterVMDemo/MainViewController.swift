
import UIKit
import CoreBluetooth
import CoreLocation
import CoreMotion
import TJJupiterVMSDK

class MainViewController: UIViewController, TJJupiterVMDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate {
    private let enabledButtonColor = UIColor(hex: "#E47325")
    private let pressedButtonColor = UIColor(hex: "#C95D17")
    private let disabledButtonColor = UIColor(hex: "#D3D7DC")
    private let disabledTitleColor = UIColor(hex: "#7E8792")
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
    private var isShowingMap = false
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
        print("(MainViewController) onJupiterSuccess -> isSuccess: \(isSuccess), code: \(code)")
    }
    
    func onJupiterResult(_ result: TJJupiterVMSDK.JupiterResult) {
        // TODO
    }
    
    func onWebViewSuccess(_ isSuccess: Bool, _ code: TJJupiterVMSDK.VMErrorCode?) {
        isShowingMap = false

        if isSuccess {
            print("(MainViewController) onWebViewSuccess -> isSuccess: \(isSuccess), code: \(code)")
            self.startService()
        } else {
            self.vmView.removeFromSuperview()
        }

        refreshButtonAvailability()
    }
    
    func didWebViewRemoved() {
        isShowingMap = false
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
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let initMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("실내지도 초기화", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor(hex: "#E47325")
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.isEnabled = false
        return button
    }()
    
    private let showMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("실내지도 보기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor(hex: "#E47325")
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.isEnabled = false
        return button
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    @objc func initMapTapped() {
        isInitializingMap = true
        refreshButtonAvailability()
        self.initVMView()
    }
    
    func resetInitMapButton() {
        isInitializingMap = false
        refreshButtonAvailability()
    }
    
    @objc func showMapTapped() {
        isShowingMap = true
        refreshButtonAvailability()
        self.setupVMView()
    }
    
    func resetShowMapButton() {
        isShowingMap = false
        refreshButtonAvailability()
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
        
        view.addSubview(containerView)
        containerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(initMapButton)
        buttonStackView.addArrangedSubview(showMapButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            buttonStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            buttonStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -24),
            buttonStackView.widthAnchor.constraint(equalToConstant: 220),

            initMapButton.heightAnchor.constraint(equalToConstant: 52),
            showMapButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        bindButtonActions()
        refreshButtonAvailability()
    }

    private func bindButtonActions() {
        initMapButton.addTarget(self, action: #selector(initMapTapped), for: .touchUpInside)
        showMapButton.addTarget(self, action: #selector(showMapTapped), for: .touchUpInside)

        [initMapButton, showMapButton].forEach { button in
            button.addTarget(self, action: #selector(handleButtonPressDown(_:)), for: [.touchDown, .touchDragEnter])
            button.addTarget(self, action: #selector(handleButtonPressUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        }
    }

    private func setButtonEnabled(_ button: UIButton, isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.backgroundColor = isEnabled ? enabledButtonColor : disabledButtonColor
        button.setTitleColor(isEnabled ? .white : disabledTitleColor, for: .normal)
        button.transform = .identity
        button.layer.shadowOpacity = isEnabled ? 0.16 : 0.0
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
        let targetColor = sender.isEnabled ? enabledButtonColor : disabledButtonColor

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

    @objc private func handleAppWillEnterForeground() {
        evaluateLaunchRequirements()
    }

    private func evaluateLaunchRequirements() {
        let missingKeys = missingRequiredUsageDescriptionKeys()
        if !missingKeys.isEmpty {
            hasRequiredPermissions = false
            refreshButtonAvailability()
            presentPermissionIssueIfNeeded(.missingPlistKeys(missingKeys))
            return
        }

        let permissionState = evaluatePermissions()
        hasRequiredPermissions = permissionState.allGranted
        refreshButtonAvailability()

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
        let canInit = hasRequiredPermissions
            && authState == .succeeded
            && !isInitializingMap
            && !hasInitializedMap
        let canShowMap = hasRequiredPermissions
            && authState == .succeeded
            && hasInitializedMap
            && !isShowingMap

        setButtonEnabled(initMapButton, isEnabled: canInit)
        setButtonEnabled(showMapButton, isEnabled: canShowMap)
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
            return (false, false, .motionDenied)
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

        let now = Date()
        let startDate = now.addingTimeInterval(-60)

        motionActivityManager.queryActivityStarting(from: startDate, to: now, to: .main) { [weak self] _, _ in
            guard let self else { return }
            self.isRequestingMotionPermission = false
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
        case .missingPlistKeys:
            break
        }

        present(alert, animated: true)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        evaluateLaunchRequirements()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
    
    func setupVMView() {
        vmView.configureFrame(to: self.containerView)
    }
    
    func startService() {
        vmView.startService()
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
        if let existingView = selectVehicleView {
            existingView.removeFromSuperview()
            selectVehicleView = nil
        }

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
}
