//
//  BleTransportConfiguration.swift
//  BleTransport
//
//  Created by Dante Puglisi on 5/10/22.
//  Modernized by NovaShieldWallet 2026.
//

import Foundation
import CoreBluetooth

/// Configuration defining which Ledger device services to scan for and connect to.
///
/// The default configuration supports all current Ledger devices:
/// - Ledger Nano X
/// - Ledger Nano FTS (Nano S Plus)
/// - Ledger Stax
/// - Ledger Flex
public final class BleTransportConfiguration {
    
    /// The BLE services to scan for and communicate with.
    let services: [BleService]
    
    /// The service currently being used for the active connection.
    var connectedService: BleService?
    
    /// Creates a configuration with the specified BLE services.
    ///
    /// - Parameter services: Array of `BleService` definitions to scan for.
    public init(services: [BleService]) {
        self.services = services
    }
    
    /// Creates the default configuration supporting all Ledger device models.
    ///
    /// This includes service UUIDs for:
    /// - **Nano X**: `13D63400-2C97-0004-0000-4C6564676572`
    /// - **Nano FTS (S Plus)**: `13D63400-2C97-6004-0000-4C6564676572`
    /// - **Stax**: `13D63400-2C97-3004-0000-4C6564676572`
    /// - **Flex**: `13D63400-2C97-4004-0000-4C6564676572`
    static func defaultConfig() -> BleTransportConfiguration {
        return BleTransportConfiguration(services: [
            .nanoX,
            .nanoFTS,
            .stax,
            .flex,
        ])
    }
    
    /// Finds the service configuration matching the given service UUID.
    ///
    /// - Parameter serviceUUID: The `CBUUID` to match against.
    /// - Returns: The matching `BleService`, or `nil` if no match is found.
    public func serviceMatching(serviceUUID: CBUUID) -> BleService? {
        return services.first { $0.service.uuid == serviceUUID }
    }
}

// MARK: - BLE Service Definition

/// Defines a Ledger device's BLE service and its associated characteristics.
///
/// Each Ledger device model uses a unique set of UUIDs for its service
/// and read/write characteristics. This struct encapsulates that configuration.
public final class BleService {
    
    /// The BLE service identifier.
    let service: ServiceIdentifier
    
    /// The characteristic used to receive notifications from the device.
    let notify: CharacteristicIdentifier
    
    /// The characteristic for writes that require a response.
    let writeWithResponse: CharacteristicIdentifier
    
    /// The characteristic for writes without response (faster but no delivery guarantee).
    let writeWithoutResponse: CharacteristicIdentifier
    
    /// Creates a BLE service configuration with the specified UUIDs.
    ///
    /// - Parameters:
    ///   - serviceUUID: The 128-bit UUID string for the BLE service.
    ///   - notifyUUID: UUID for the notify characteristic.
    ///   - writeWithResponseUUID: UUID for the write-with-response characteristic.
    ///   - writeWithoutResponseUUID: UUID for the write-without-response characteristic.
    public init(serviceUUID: String, notifyUUID: String, writeWithResponseUUID: String, writeWithoutResponseUUID: String) {
        let service = ServiceIdentifier(uuid: serviceUUID)
        self.notify = CharacteristicIdentifier(uuid: notifyUUID, service: service)
        self.writeWithResponse = CharacteristicIdentifier(uuid: writeWithResponseUUID, service: service)
        self.writeWithoutResponse = CharacteristicIdentifier(uuid: writeWithoutResponseUUID, service: service)
        self.service = service
    }
    
    /// Returns the appropriate write characteristic based on the device's capability.
    func writeCharacteristic(canWriteWithoutResponse: Bool) -> CharacteristicIdentifier {
        return canWriteWithoutResponse ? writeWithoutResponse : writeWithResponse
    }
}

// MARK: - Pre-defined Device Services

extension BleService {
    
    /// Ledger Nano X BLE service configuration.
    public static let nanoX = BleService(
        serviceUUID: "13D63400-2C97-0004-0000-4C6564676572",
        notifyUUID: "13D63400-2C97-0004-0001-4C6564676572",
        writeWithResponseUUID: "13D63400-2C97-0004-0002-4C6564676572",
        writeWithoutResponseUUID: "13D63400-2C97-0004-0003-4C6564676572"
    )
    
    /// Ledger Nano FTS (Nano S Plus) BLE service configuration.
    public static let nanoFTS = BleService(
        serviceUUID: "13D63400-2C97-6004-0000-4C6564676572",
        notifyUUID: "13D63400-2C97-6004-0001-4C6564676572",
        writeWithResponseUUID: "13D63400-2C97-6004-0002-4C6564676572",
        writeWithoutResponseUUID: "13D63400-2C97-6004-0003-4C6564676572"
    )
    
    /// Ledger Stax BLE service configuration.
    public static let stax = BleService(
        serviceUUID: "13D63400-2C97-3004-0000-4C6564676572",
        notifyUUID: "13D63400-2C97-3004-0001-4C6564676572",
        writeWithResponseUUID: "13D63400-2C97-3004-0002-4C6564676572",
        writeWithoutResponseUUID: "13D63400-2C97-3004-0003-4C6564676572"
    )
    
    /// Ledger Flex BLE service configuration.
    public static let flex = BleService(
        serviceUUID: "13D63400-2C97-4004-0000-4C6564676572",
        notifyUUID: "13D63400-2C97-4004-0001-4C6564676572",
        writeWithResponseUUID: "13D63400-2C97-4004-0002-4C6564676572",
        writeWithoutResponseUUID: "13D63400-2C97-4004-0003-4C6564676572"
    )
}
