# TJJupiterVMSDK
### Version 1.0.23

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

## 🔄 Migration Guide (1.0.22 → 1.0.23)

If you are upgrading from 1.0.22 or earlier, check the items below. Existing single-sector code keeps working except for **Breaking Changes**.

### ⚠️ Breaking Changes

| Before (≤ 1.0.22) | After (1.0.23) | Action |
|---|---|---|
| `setMockMode(mode:completion:)` | `setMockMode(mode:sectorId:completion:)` | Pass the sector whose simulation data to use. See [Mocking Mode](#9-mocking-mode). |

New enum cases were added. If you `switch` over these enums **exhaustively without `default`**, add the new cases:

| Enum | Added cases |
|---|---|
| `JupiterErrorCode` | `INVALID_SECTOR = 3` |
| `VMErrorCode` | `INVALID_SECTOR = 403` |

### 🔁 Behavior Changes

These require no code changes, but the SDK behaves differently after upgrading.

- **Map zoom range follows the sector configuration.** If the sector has a zoom level configured on the server, the map opens at that default zoom and limits zooming to its min/max range. Sectors without the configuration keep the previous map defaults.
- **`stopService` ends navigation.** The destination and route are cleared when the service stops. After restarting, request the route again from the map.
- **Mocking mode fixes the sector.** While mocking mode is on, `configureFrame` and `startService` must be called with the mock sector's `sectorId`; another sector fails with `INVALID_SECTOR`. See [Mocking Mode](#9-mocking-mode).

### ✨ New Features

- **Multi-sector support.** Load several sectors once and switch between them without re-initializing. See [Initialize](#4-create-vm-view) and [Switch Sectors](#8-switch-sectors-multi-sector).
    - `initialize(userId:sectorIds:debugOption:)`
    - `configureFrame(to:sectorId:)` and `startService(sectorId:)` — `sectorId` is required; the SDK never picks a sector for you.
    - The single-sector `initialize(userId:sectorId:debugOption:)` still works.

### 🛠 Fixes

- `EnteringInfo` fields (`id`, `number`, `name`) are now `public`. Previously they could not be read outside the SDK.

### 📝 Documentation Fixes

The previous README did not match the SDK in the following places. The SDK API itself did not change.

- `isParkingLocationTapped(levelId:parkingLocationId:)` — `levelId` is a `String`, not `Int`.
- Parking location APIs take `String` level keys (level_matches), not `Int`.
- `JupiterVMRegion` has only `KOREA` and `SAUDI`.
- `VMErrorCode` includes `NOT_INITIALIZED = 401`.

---

## 🏁 Guide

### 1. Import

```swift
import TJJupiterVMSDK
```

### 2. Server Configuration (Optional)

- Sets the service `region` and server `branch` (PROD / DEV) for **all** SDK components (Auth, Jupiter, VM).
- This is the single source of truth: `TJJupiterVMView.initialize` reads the same `region`/`branch`, so you only configure it here.
- If called, it **must** be called **before** `auth` and `initialize`.
- Default is `.SAUDI` region on the `.PROD` branch, so you can skip this step for that configuration.

```swift
TJJupiterVMAuth.shared.setServerConfig(region: .SAUDI, branch: .PROD)
```

### 3. Authentication

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

### 4. Create VM View

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
        vmView.configureFrame(to: view, sectorId: 20)
    }
}
```

To use multiple sectors, pass all sector IDs at initialization. Resources for every sector are loaded once; the sector to use is chosen in `configureFrame` / `startService`. If any sector fails to load, initialization fails.

```swift
vmView.initialize(
    userId: "USER_ID",
    sectorIds: [20, 21]
)
```

### 5. Remove VM View

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
        vmView.configureFrame(to: view, sectorId: 20)
    }

    func closeView() {
        vmView.closeFrame()
    }
}
```

### 6. Start Service

```swift
// `sectorId` is required and must be one of the sectors loaded at initialization
vmView.startService(sectorId: 20)
```

### 7. Stop Service

```swift
vmView.stopService { success, message in
    print("Stopped:", success, message)
}
```

### 8. Switch Sectors (Multi-sector)

- The map and positioning always use the same sector.
- `configureFrame(to:sectorId:)` and `startService(sectorId:)` both require a `sectorId`, even when a single sector was loaded.
- Whichever of the two succeeds first fixes the sector. The other must use the same sector:
    - `configureFrame` with a different or unloaded sector fails with `onWebViewSuccess(false, .INVALID_SECTOR)`.
    - `startService` with a different or unloaded sector fails with `onJupiterSuccess(false, .INVALID_SECTOR)`.
- To switch sectors, **stop the service and close the frame**, then configure and start with the new sector. No re-initialization is needed.

```swift
// Sector 20
vmView.configureFrame(to: view, sectorId: 20)
vmView.startService(sectorId: 20)

// Switch to sector 21
vmView.stopService { _, _ in }
vmView.closeFrame()
vmView.configureFrame(to: view, sectorId: 21)
vmView.startService(sectorId: 21)
```

### 9. Mocking Mode

- Jupiter positions with TJLABS BLE beacons, so no indoor result is produced outside the service area. Mocking mode replays predefined results instead.
- Specify the sector whose simulation data is used. It must be a sector loaded at initialization.
- Set it **before** `configureFrame` / `startService`. If a sector is already fixed by `configureFrame` / `startService` and differs from `sectorId`, `success` is false.
- While mocking mode is on, `configureFrame` and `startService` must be called with the mock sector's `sectorId`; another sector fails with `INVALID_SECTOR`.
- `.NONE` turns mocking mode off; `sectorId` is ignored.

```swift
vmView.setMockMode(mode: .VEHICLE_INDOOR_OUTDOOR, sectorId: 20) { success in
    print("Mock mode:", success)
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

    func isParkingLocationTapped(levelId: String, parkingLocationId: String) {}
}
```

---

## 🚗 Parking Location

- Keys are your level identifiers (level_matches, e.g. `"B2"`), and values are your parking location IDs (matching IDs).
- Levels or IDs that do not match the sector in use are ignored.

### Set Saved Parking Locations

```swift
vmView.setSavedParkingLocations(
    parkingLocations: [
        "B2": ["PARKING-A-101", "PARKING-A-102"]
    ]
)
```

### Update Saved Parking Locations

```swift
vmView.updateSavedParkingLocations(
    parkingLocations: [
        "B2": ["PARKING-A-103"]
    ]
)
```

### Set Parking Locations States

```swift
vmView.setParkingLocationStates(
    parkingLocationStates: [
        "B2": [
            "PARKING-A-101": .VACANT,
            "PARKING-A-102": .OCCUPIED
        ]
    ]
)
```

### Update Parking Location States

```swift
vmView.updateParkingLocationStates(
    parkingLocationStates: [
        "B2": [
            "PARKING-A-103": .VACANT
        ]
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
    public var remaining_distance: Int?   // meters to the destination (vehicle mode with a route only)
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
    case SAUDI = "SAUDI"
}
```

### InitErrorCode

```swift
public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case NETWORK_DISCONNECT = 2
    case LOGIN_FAIL = 3
    case LOAD_RESOURCE_FAIL = 4
}
```

### JupiterErrorCode

```swift
public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 0
    case DUPLICATED_SERVICE = 1
    case GENERATOR_FAIL = 2
    case INVALID_SECTOR = 3   // startService: sector not loaded, or different from the sector fixed by configureFrame
}
```

### VMErrorCode

```swift
public enum VMErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 401
    case VM_VIEW_FAIL  = 402
    case INVALID_SECTOR = 403   // configureFrame: sector not loaded, or different from the sector fixed by startService
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
