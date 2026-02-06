# LedgerBleTransport

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Native BLE (Bluetooth Low Energy) transport for communicating with [Ledger](https://www.ledger.com) hardware wallets on iOS and macOS.

> **Fork of [LedgerHQ/hw-transport-ios-ble](https://github.com/LedgerHQ/hw-transport-ios-ble)** — modernized for Swift 6, with security hardening, expanded device support, and a developer-friendly API.

## Supported Devices

| Device | Status |
|--------|--------|
| Ledger Nano X | Supported |
| Ledger Nano S Plus (FTS) | Supported |
| Ledger Stax | Supported |
| Ledger Flex | Supported |

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/NovaShieldWallet/ledger-swift-sdk.git", from: "2.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...** and enter:
```
https://github.com/NovaShieldWallet/ledger-swift-sdk.git
```

## Quick Start

### Scan for Devices

```swift
import BleTransport

// Async stream of discovered devices
for try await devices in BleTransport.shared.scan(duration: 10) {
    for device in devices {
        print("Found: \(device.peripheral.name) (RSSI: \(device.rssi))")
    }
}
```

### Connect to First Available Device

```swift
let peripheral = try await BleTransport.shared.create(
    scanDuration: 10,
    disconnectedCallback: {
        print("Device disconnected")
    }
)
print("Connected to: \(peripheral.name)")
```

### Connect to a Specific Device

```swift
// By identifier
try await BleTransport.shared.connect(
    toPeripheralID: peripheralIdentifier,
    disconnectedCallback: nil
)

// By name
try await BleTransport.shared.connect(
    toPeripheralNamed: "Nano X 1A2B",
    disconnectedCallback: nil
)
```

### Exchange APDU Commands

```swift
// Send an APDU and get the response
let response = try await BleTransport.shared.exchange(
    apdu: APDU(data: [0xb0, 0x01, 0x00, 0x00])
)
print("Response: \(response)")

// Or from a hex string
let apdu = APDU(raw: "e0d8000007426974636f696e")
let result = try await BleTransport.shared.exchange(apdu: apdu)
```

### Query Device App Info

```swift
let appInfo = try await BleTransport.shared.getAppAndVersion()
print("Running: \(appInfo.name) v\(appInfo.version)")
```

### Open an App on the Device

```swift
// Opens Bitcoin app, closing current app if needed
try await BleTransport.shared.openAppIfNeeded("Bitcoin")
```

### Disconnect

```swift
try await BleTransport.shared.disconnect()
```

### Monitor Bluetooth State

```swift
let state = await BleTransport.shared.bluetoothStateCallback()
print("Bluetooth state: \(state.rawValue)")
```

## Callback-Based API

All async methods also have callback-based equivalents for compatibility:

```swift
BleTransport.shared.scan(duration: 10) { devices in
    print("Found \(devices.count) devices")
} stopped: { error in
    if let error = error {
        print("Scan error: \(error.localizedDescription)")
    }
}

BleTransport.shared.connect(
    toPeripheralID: peripheral,
    disconnectedCallback: nil,
    success: { connectedPeripheral in
        print("Connected!")
    },
    failure: { error in
        print("Failed: \(error.localizedDescription)")
    }
)
```

## Custom Configuration

By default, `BleTransport` scans for all supported Ledger devices. You can customize:

```swift
// Scan only for specific device models
let config = BleTransportConfiguration(services: [
    .nanoX,    // Ledger Nano X
    .nanoFTS,  // Ledger Nano S Plus
    .stax,     // Ledger Stax
    .flex,     // Ledger Flex
])
```

## Error Handling

The SDK provides typed errors for precise error handling:

```swift
do {
    try await BleTransport.shared.connect(
        toPeripheralID: peripheral,
        disconnectedCallback: nil
    )
} catch let error as BleTransportError {
    switch error {
    case .bluetoothNotAvailable:
        print("Please enable Bluetooth")
    case .scanningTimedOut:
        print("No device found")
    case .connectError(let description):
        print("Connection failed: \(description)")
    case .pairingError(let description):
        print("Pairing failed: \(description)")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Info.plist Configuration

Add the following to your app's `Info.plist` for Bluetooth access:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with your Ledger device.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

## Demo App

The repository includes demo applications. Open `BleTransportDemo/BleTransportDemo.xcodeproj` and run:
- **BleTransportDemo** — iOS demo
- **BleTransportDemoMac** — macOS demo

## What Changed from the Original

This fork includes significant improvements over the original [LedgerHQ/hw-transport-ios-ble](https://github.com/LedgerHQ/hw-transport-ios-ble):

### Modernization
- **Swift 6.0** with swift-tools-version 6.0
- **iOS 17+ / macOS 14+** platform targets
- Removed legacy `@objc` annotations and unnecessary `NSObject` inheritance
- Renamed `Sendable` protocol to `BluetoothSendable` (Swift's built-in `Sendable` conflict)

### Security Hardening
- Eliminated all force unwraps (`!`) — safe parsing throughout
- Added bounds checking in APDU response parsing (prevents crashes on malformed data)
- MTU negotiation validates range (20-512 bytes per BLE spec)
- Replaced `print()` debug statements with `os.Logger` using privacy annotations
- APDU data is never logged in production builds

### New Device Support
- Added Ledger Stax BLE service UUIDs
- Added Ledger Flex BLE service UUIDs
- Named static constants: `BleService.nanoX`, `.nanoFTS`, `.stax`, `.flex`

### Bug Fixes
- Fixed `openApp`/`closeApp` calling `BleTransport.shared` instead of `self`
- Fixed `PeripheralIdentifier` hash/equality inconsistency
- Fixed potential crash in `parseMTUresponse` with short responses

### Testing
- Expanded from 14 to 69 unit tests
- Security-focused test suite for hex parsing and bounds checking
- Configuration and error type test coverage

## License

MIT — see [LICENSE](LICENSE) for details.

## Resources

- [Ledger Developer Portal](https://developers.ledger.com/)
- [Ledger Devs Discord](https://developers.ledger.com/discord-pro)
