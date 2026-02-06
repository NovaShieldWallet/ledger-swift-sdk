//
//  BluetoothSendable.swift
//  BleTransport
//
//  Created by Dante Puglisi on 8/3/22.
//  Updated by NovaShieldWallet 2026.
//

import Foundation

/// Protocol to indicate that a type can be sent via the Bluetooth connection.
///
/// Renamed from `Sendable` to `BluetoothSendable` to avoid conflict with
/// Swift's built-in `Swift.Sendable` protocol used for concurrency safety.
public protocol BluetoothSendable {
    
    /// Serialize this value into `Data` suitable for BLE transmission.
    func toBluetoothData() -> Data
}
