# TJJupiterVMSDK
### Version 1.0.1

[![Version](https://img.shields.io/cocoapods/v/TJJupiterVMSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterVMSDK)
[![License](https://img.shields.io/cocoapods/l/TJJupiterVMSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterVMSDK)
[![Platform](https://img.shields.io/cocoapods/p/TJJupiterVMSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterVMSDK)

TJJupiterVMSDK is an iOS SDK that provides a Jupiter-based indoor positioning engine together with a VM (WebView) UI.

It provides real-time indoor positioning results, VM screen initialization, ward entry events, parking location selection, and vacant parking space status updates.

---

## ✨ Features

- 📍 Jupiter-based indoor positioning result delivery
- 🖥️ VM (WebView) screen integration
- 🅿️ Parking location save / select / status display
- 💡 Ward entry event detection
- 🔄 Real-time positioning result stream

---

## 📦 Requirements

- iOS 16.0+
- Swift 5.0+
- Info.plist
    - Privacy - Motion Usage Description
    - Privacy - Bluetooth Peripheral Usage Description
    - Privacy - Bluetooth Always Usage Description
    - Privacy - Location When In Use Usage Description
    - Required device capabilities
        - item : Accelerometer
        - item : Gyroscope
        - item : Magnetometer
        - item : Bluetooth Low Energy
    - Required background modes
        - App communicates using CoreBluetooth
        - App registers for location updates

---

## 🚀 Installation

### CocoaPods

```ruby
pod 'TJJupiterVMSDK'
```

If you cannot find `TJJupiterVMSDK` in CocoaPods, add the default Specs source to your `Podfile`.

```ruby
source 'https://github.com/CocoaPods/Specs.git'
```

---

## 🏁 Guide

### 1. Import

```swift
import TJJupiterVMSDK
```

### 2. Authentication

- Authentication is required before using the SDK.
- You must authenticate first using your issued `accessKey` and `secretAccessKey`.

```swift
TJJupiterVMAuth.shared.auth(
    accessKey: "YOUR_ACCESS_KEY",
    secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
) { code, success in
    print("Auth:", code, success)
}
```

### 3. Create VM View

```swift
import UIKit
import TJJupiterVMSDK

final class ViewController: UIViewController {
    private let vmView = TJJupiterVMView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        vmView.delegate = self
        vmView.initialize(
            userId: "USER_ID",
            sectorId: 20
        )
        vmView.configureFrame(to: view)
    }
}
```

### 3. Remove VM View

```swift
import UIKit
import TJJupiterVMSDK

final class ViewController: UIViewController {
    private let vmView = TJJupiterVMView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        vmView.delegate = self
        vmView.initialize(
            userId: "USER_ID",
            sectorId: 20
        )
        vmView.configureFrame(to: view)
    }

    func closeView() {
        vmView.closeFrame()
    }
}
```

### 5. Start Service

```swift
vmView.startService()
```

### 6. Stop Service

```swift
vmView.stopService { success, message in
    print("Stopped:", success, message)
}
```

---

## 📡 Delegate

```swift
extension ViewController: TJJupiterVMDelegate {

    func onInitSuccess(_ isSuccess: Bool, _ code: InitErrorCode?) {}

    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?) {}

    func onJupiterResult(_ result: JupiterResult) {}

    func onWebViewSuccess(_ isSuccess: Bool, _ code: VMErrorCode?) {}

    func didWebViewRemoved() {}

    func isEnteringWardDeteced(info: EnteringInfo) {}

    func isParkingLocationTapped(_ parkingLocationId: String) {}
}
```

---

## 🚗 Parking Location

### Saved Parking Locations

```swift
vmView.setSavedParkingLocations(
    parkingLocationIds: ["PARKING-A-101", "PARKING-A-102"]
)
```

### Vacant Parking Locations

```swift
vmView.setVacantParkingLocations(
    levelId: 2,
    parkingLocationStates: [
        "PARKING-A-101": .VACANT,
        "PARKING-A-102": .OCCUPIED
    ]
)
```

### Update Vacant Parking Locations

```swift
vmView.updateVacantParkingLocations(
    levelId: 2,
    parkingLocationStates: [
        "PARKING-A-103": .VACANT
    ]
)
```

---

## 📚 Position Result

### JupiterResult

```swift
public struct JupiterResult: Codable {
    public var mobile_time: Int
    public var index: Int
    public var building_name: String
    public var level_name: String
    public var jupiter_pos: Position
    public var navi_pos: Position?
    public var llh: LLH?
    public var velocity: Float
    public var is_vehicle: Bool
    public var is_indoor: Bool
    public var validity_flag: Int
}
```

### Position

```swift
public struct Position: Codable {
    public var x: Float
    public var y: Float
    public var heading: Float
}
```

### LLH

```swift
public struct LLH: Codable {
    public var lat: Double
    public var lon: Double
    public var azimuth: Double
}
```

---

## 📚 Core Enums

### JupiterVMRegion

```swift
public enum JupiterVMRegion: String {
    case KOREA = "KOREA"
    case US_EAST = "US_EAST"
    case CANADA = "CANADA"
    case SAUDI = "SAUDI"
}
```

### InitErrorCode

```swift
public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case INVALID_MODE = 2
    case NETWORK_DISCONNECT = 3
    case DUPLICATED_SERVICE = 4
    case LOGIN_FAIL = 5
    case CALC_INIT_FAIL = 6
}
```

### JupiterErrorCode

```swift
public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case INVALID_ID = 0
    case INVALID_MODE = 1
    case NETWORK_DISCONNECT = 2
    case DUPLICATED_SERVICE = 3
    case LOGIN_FAIL = 4
    case GENERATOR_FAIL = 5
    case CALC_INIT_FAIL = 6
}
```

### VMErrorCode

```swift
public enum VMErrorCode: Int {
    case UNKNOWN = -1
    case VM_VIEW_FAIL  = 402
}
```

### ParkingLocationState

```swift
public enum ParkingLocationState: Int {
    case UNKNOWN = -1
    case VACANT = 0
    case OCCUPIED = 1
}
```

---

## 📌 Example

- For a more detailed example, please refer to the demo project at the link below.
- https://github.com/tjlabs/TJJupiterVM-demo-ios

---

## 📄 License

TJJupiterVMSDK is proprietary software provided by TJLabs under a separate commercial license agreement. Redistribution is not permitted except as agreed in writing.
