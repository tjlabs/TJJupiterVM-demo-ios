# TJJupiterVM-demo-ios

## Overview

TJJupiterVM-demo-ios is a minimal iOS sample app for integrating **TJLabs Jupiter VM SDK** with `UIKit`.

<!-- JUPITER_SDK_VERSION_START -->
Jupiter SDK version: 2.0.0
<!-- JUPITER_SDK_VERSION_END -->

<!-- JUPITER_VM_SDK_VERSION_START -->
Jupiter VM SDK (CocoaPods): TJJupiterVMSDK 1.0.2
<!-- JUPITER_VM_SDK_VERSION_END -->

The app demonstrates the VM SDK lifecycle step by step:
- Authentication (`AUTH`)
- Service initialize (`initialize`)
- Mock mode apply (`setMockMode`)
- VM frame attach (`configureFrame`)
- VM frame detach (`closeFrame`)
- Service start (`startService`)
- Service stop (`stopService`)
- Parking location APIs (`setSavedParkingLocations`, `setParkingLocationStates`, `updateSavedParkingLocations`)

## Features

- Permission check and auth flow on launch
- Step-by-step lifecycle controls for `initialize`, `setMockMode`, `configureFrame`, `closeFrame`, `startService`, and `stopService`
- UIKit-based VM frame attach/detach flow
- Runtime motion, location, and Bluetooth permission request flow
- Mock Mode selector for switching VM scenarios after initialization
- Parking-space tap callback handling
- Hardcoded saved parking / parking-state example after initialization

## Requirements

- iOS `16.0+`
- Xcode (latest stable recommended)
- Swift-based iOS app
- UIKit
- CocoaPods

### Required plist entries

Declare in `Info.plist`:

- `Privacy - Motion Usage Description` (`NSMotionUsageDescription`)
- `Privacy - Bluetooth Peripheral Usage Description` (`NSBluetoothPeripheralUsageDescription`)
- `Privacy - Bluetooth Always Usage Description` (`NSBluetoothAlwaysUsageDescription`)
- `Privacy - Location When In Use Usage Description` (`NSLocationWhenInUseUsageDescription`)

### Required device capabilities

- `item : Accelerometer`
- `item : Gyroscope`
- `item : Magnetometer`
- `item : Bluetooth Low Energy`

### Required background modes

- `App communicates using CoreBluetooth` (`bluetooth-central`)
- `App registers for location updates` (`location`)

Runtime permission check in this demo requires:
- Motion
- Location When In Use
- Bluetooth

## Setup

### 1. Add dependency

This demo uses a local SDK path in `Podfile`:

```ruby
platform :ios, '16.0'

target 'TJJupiterVMDemo' do
  use_frameworks!

  pod 'TJJupiterVMSDK'
end
```

If you use a different local path, update the `:path` value.

### 2. Install pods

```bash
pod install
```

### 3. Open workspace

Open:

```text
TJJupiterVMDemo.xcworkspace
```

## Quick Guide

### 1. Configure credentials

Set your issued credentials in the auth call used by this demo.

Input:
- `accessKey: String`
- `secretAccessKey: String`

Output:
- callback `(code: Int, success: Bool)`

```swift
TJJupiterVMAuth.shared.auth(
    accessKey: "YOUR_ACCESS_KEY",
    secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
) { code, success in
    // handle auth result
}
```

In this demo, the auth call is implemented in `MainViewController.doAuth()`.

### 2. Launch flow: permissions -> auth

```swift
func doAuth() {
    TJJupiterVMAuth.shared.auth(
        accessKey: "YOUR_ACCESS_KEY",
        secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
    ) { code, success in
        // update UI state
    }
}
```

When the app launches:
- Motion, location, and Bluetooth permissions are checked first.
- After all required permissions are granted, auth runs automatically.
- `initialize` becomes enabled only after auth succeeds.

### 3. Step-by-step lifecycle test flow

After auth succeeds, the demo lets you test each stage separately.

1. Tap `initialize`
2. Optionally choose a scenario from `Mock Mode`
3. Tap `configureFrame` if you want to attach the VM web frame to the on-screen container
4. Tap `startService`
5. Tap `stopService`
6. Tap `closeFrame` when you want to detach the frame

`configureFrame` / `closeFrame` and `startService` / `stopService` are intentionally separated so you can verify frame lifecycle and service lifecycle independently.

### 4. Initialize service

Input:
- `userId: String`
- `sectorId: Int`
- `region: JupiterVMRegion` (default: `JupiterVMRegion.SAUDI`)

Output:
- `onInitSuccess(isSuccess, code)`

```swift
vmView.delegate = self
vmView.initialize(
    userId: "vm-test",
    sectorId: 20
)
```

Behavior in this demo:
- `initialize` is enabled only once after successful auth
- On successful initialization, sample saved parking and parking-state data are applied

### 5. Apply Mock Mode

Input:
- `mode: JupiterMockMode`

Output:
- completion `(isSuccess: Bool)`

```swift
vmView.setMockMode(mode: .VEHICLE_OUTDOOR_PARKING) { isSuccess in
    // update UI state
}
```

Behavior in this demo:
- `Mock Mode` becomes available after `initialize`
- Available options are `None`, `Vehicle Outdoor Start`, `Vehicle Indoor Start`, `Pedestrian Indoor Start`, and `Pedestrian POI Start`
- `startService` stays disabled while a Mock Mode change is being applied

### 6. Attach VM frame with `configureFrame`

Input:
- host `UIView`

Output:
- `onWebViewSuccess(isSuccess, code)`
- `didWebViewRemoved()`

```swift
vmView.configureFrame(to: containerView)
```

Behavior in this demo:
- `configureFrame` attaches the VM frame to the dedicated container view
- `closeFrame` removes the attached frame
- Frame attach/detach does not automatically start or stop the service

### 7. Start and stop service

```swift
vmView.startService()

vmView.stopService { isSuccess, message in
    // update UI state
}
```

Behavior in this demo:
- `startService` is triggered explicitly by the button
- `stopService` is also triggered explicitly and updates button state in its completion
- Service start/stop is documented separately from frame attach/detach so each SDK step can be tested on its own

### 8. Parking APIs in this demo

Saved parking example:

```swift
vmView.setSavedParkingLocations(parkingLocations: [
    52: ["OB-uvbd7yeu7zab3948"]
])
```

Parking-state example:

```swift
let states: [String: ParkingLocationState] = [
    "OB-1h82101id68tx3548": .VACANT,
    "OB-1h7zbmxfa10z93809": .VACANT,
    "OB-1h84se62jidlw3811": .VACANT
]

vmView.setParkingLocationStates(parkingLocationStates: [
    52: states
])
```

Parking-space tap handling in this demo:

```swift
vmView.updateSavedParkingLocations(parkingLocations: [
    levelId: [parkingLocationId]
])
```
