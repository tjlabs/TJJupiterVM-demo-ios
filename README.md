# TJJupiterVM-demo-ios

## Overview

TJJupiterVM-demo-ios is a minimal iOS sample app for integrating **TJLabs Jupiter VM SDK** with `UIKit`.

<!-- JUPITER_SDK_VERSION_START -->
Jupiter SDK version: 2.0.0
<!-- JUPITER_SDK_VERSION_END -->

<!-- JUPITER_VM_SDK_VERSION_START -->
Jupiter VM SDK (CocoaPods): TJJupiterVMSDK 1.0.0
<!-- JUPITER_VM_SDK_VERSION_END -->

The app demonstrates a simple VM service lifecycle with:
- Authentication (`AUTH`)
- Service initialize (`실내지도 초기화`)
- VM view attach and service start (`실내지도 보기`)
- Parking location APIs (`setSavedParkingLocations`, `setVacantParkingLocations`)

## Features

- VM SDK auth/init/start flow example
- UIKit-based VM view attach flow
- Runtime location and Bluetooth permission request flow
- Parking-space tap callback handling
- Hardcoded vacant parking update example

## Requirements

- iOS `16.0+`
- Xcode (latest stable recommended)
- Swift-based iOS app
- UIKit
- CocoaPods

### Required permissions

Declare in `Info.plist`:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSBluetoothAlwaysUsageDescription`
- `UIBackgroundModes` with `location`
- `UIBackgroundModes` with `bluetooth-central`

Runtime permission check in this demo requires:
- Location
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

### 2. Authenticate

This demo authenticates before enabling the initialize/show buttons.

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

### 3. Initialize service

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

### 4. Show VM view and start service

This demo first attaches the VM view, then starts the service after `onWebViewSuccess`.

Input:
- host `UIView`

Output:
- `onWebViewSuccess(isSuccess, code)`
- `onJupiterSuccess(isSuccess, code)`
- `onJupiterResult(result)`

```swift
vmView.configureFrame(to: containerView)

func onWebViewSuccess(_ isSuccess: Bool, _ code: VMErrorCode?) {
    if isSuccess {
        vmView.startService()
    }
}
```


### 5. Parking APIs in this demo

Saved parking example:

```swift
vmView.setSavedParkingLocations(parkingLocationIds: ["OB-..."])
```

Vacant parking update example:

```swift
let states: [String: ParkingLocationState] = [
    "OB-1h82101id68tx3548": .VACANT,
    "OB-1h7zbmxfa10z93809": .VACANT,
    "OB-1h84se62jidlw3811": .VACANT
]

vmView.setVacantParkingLocations(levelId: 52, parkingLocationStates: states)
```
