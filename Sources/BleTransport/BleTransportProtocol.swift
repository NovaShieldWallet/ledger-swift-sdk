//
//  BleTransportProtocol.swift
//  BleTransport
//
//  Created by Dante Puglisi on 5/12/22.
//  Modernized by NovaShieldWallet 2026.
//

import Foundation
import CoreBluetooth

// MARK: - Type Aliases

public typealias PeripheralResponse = ((PeripheralIdentifier) -> Void)
public typealias PeripheralsWithServicesResponse = (([PeripheralInfo]) -> Void)
public typealias APDUResponse = ((APDU) -> Void)
public typealias EmptyResponse = (() -> Void)
public typealias BleErrorResponse = ((BleTransportError) -> Void)
public typealias OptionalBleErrorResponse = ((BleTransportError?) -> Void)
public typealias ErrorResponse = ((Error) -> Void)

// MARK: - Transport Protocol

/// Protocol defining the public API for Ledger BLE transport communication.
///
/// Provides both callback-based and async/await APIs for scanning, connecting,
/// and exchanging APDU messages with Ledger hardware wallets over BLE.
public protocol BleTransportProtocol: AnyObject {
    
    /// The shared singleton instance of the transport.
    static var shared: BleTransportProtocol { get }
    
    /// Whether Bluetooth is currently powered on and available.
    var isBluetoothAvailable: Bool { get }
    
    /// Whether a peripheral is currently connected.
    var isConnected: Bool { get }
    
    // MARK: - Scan
    
    /// Scan for reachable Ledger peripherals.
    ///
    /// - Parameters:
    ///   - duration: How long to scan before timing out (in seconds).
    ///   - callback: Called each time the discovered peripheral list changes.
    ///   - stopped: Called when scanning stops (with error if applicable).
    func scan(duration: TimeInterval, callback: @escaping PeripheralsWithServicesResponse, stopped: @escaping OptionalBleErrorResponse)
    
    /// Scan for reachable Ledger peripherals using an `AsyncThrowingStream`.
    ///
    /// - Parameter duration: How long to scan before timing out (in seconds).
    /// - Returns: A stream of discovered peripheral arrays.
    func scan(duration: TimeInterval) -> AsyncThrowingStream<[PeripheralInfo], Error>
    
    /// Stop an in-progress scan.
    func stopScanning()
    
    // MARK: - Connect
    
    /// Connect to a peripheral by its identifier.
    ///
    /// - Parameters:
    ///   - peripheral: The identifier of the peripheral to connect to.
    ///   - disconnectedCallback: Called if the device disconnects unexpectedly.
    ///   - success: Called on successful connection.
    ///   - failure: Called on connection failure.
    func connect(toPeripheralID peripheral: PeripheralIdentifier, disconnectedCallback: EmptyResponse?, success: @escaping PeripheralResponse, failure: @escaping BleErrorResponse)
    
    /// Connect to a peripheral by its identifier (async).
    @discardableResult
    func connect(toPeripheralID peripheral: PeripheralIdentifier, disconnectedCallback: EmptyResponse?) async throws -> PeripheralIdentifier
    
    /// Connect to a peripheral by its advertised name.
    func connect(toPeripheralNamed name: String, disconnectedCallback: EmptyResponse?, success: @escaping PeripheralResponse, failure: @escaping BleErrorResponse)
    
    /// Connect to a peripheral by its advertised name (async).
    @discardableResult
    func connect(toPeripheralNamed name: String, disconnectedCallback: EmptyResponse?) async throws -> PeripheralIdentifier
    
    /// Scan and automatically connect to the first discovered Ledger device.
    ///
    /// - Parameters:
    ///   - scanDuration: How long to scan before giving up.
    ///   - disconnectedCallback: Called if the device disconnects unexpectedly.
    ///   - success: Called on successful connection.
    ///   - failure: Called on failure.
    func create(scanDuration: TimeInterval, disconnectedCallback: EmptyResponse?, success: @escaping PeripheralResponse, failure: @escaping BleErrorResponse)
    
    /// Scan and automatically connect to the first discovered Ledger device (async).
    @discardableResult
    func create(scanDuration: TimeInterval, disconnectedCallback: EmptyResponse?) async throws -> PeripheralIdentifier
    
    // MARK: - Messaging
    
    /// Send an APDU and wait for the device's response.
    ///
    /// - Parameters:
    ///   - apduToSend: The APDU command to send.
    ///   - callback: Called with the hex-encoded response string or an error.
    func exchange(apdu apduToSend: APDU, callback: @escaping (Result<String, BleTransportError>) -> Void)
    
    /// Send an APDU and wait for the device's response (async).
    func exchange(apdu apduToSend: APDU) async throws -> String
    
    /// Send an APDU without waiting for a response.
    func send(apdu: APDU, success: @escaping EmptyResponse, failure: @escaping BleErrorResponse)
    
    /// Send an APDU without waiting for a response (async).
    func send(apdu: APDU) async throws
    
    // MARK: - Disconnect
    
    /// Disconnect from the currently connected peripheral.
    ///
    /// If an exchange is in progress, disconnection is deferred until it completes.
    ///
    /// - Parameter completion: Called when disconnection succeeds (error is nil) or fails.
    func disconnect(completion: OptionalBleErrorResponse?)
    
    /// Disconnect from the currently connected peripheral (async).
    func disconnect() async throws
    
    // MARK: - Notifications
    
    /// Register for Bluetooth availability changes.
    ///
    /// The completion is called immediately with the current state, then again on each change.
    func bluetoothAvailabilityCallback(completion: @escaping ((_ availability: Bool) -> Void))
    
    /// Register for Bluetooth state changes.
    ///
    /// The completion is called immediately with the current state, then again on each change.
    func bluetoothStateCallback(completion: @escaping ((_ state: CBManagerState) -> Void))
    
    /// Get the current Bluetooth state (async).
    func bluetoothStateCallback() async -> CBManagerState
    
    /// Register to be notified once when the current peripheral disconnects.
    func notifyDisconnected(completion: @escaping EmptyResponse)
    
    // MARK: - Device App Management
    
    /// Query the currently running app and its version on the connected device.
    func getAppAndVersion(success: @escaping ((AppInfo) -> Void), failure: @escaping ErrorResponse)
    
    /// Query the currently running app and its version (async).
    func getAppAndVersion() async throws -> AppInfo
    
    /// Open the specified app on the device, closing the current one if needed.
    func openAppIfNeeded(_ name: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Open the specified app on the device (async).
    func openAppIfNeeded(_ name: String) async throws
}

// MARK: - App Info

/// Information about the currently running app on a Ledger device.
public struct AppInfo: Swift.Sendable, Equatable {
    /// The name of the running app (e.g., "Bitcoin", "Ethereum", "BOLOS").
    public let name: String
    
    /// The version string of the running app.
    public let version: String
    
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}
