//
//  ErrorTests.swift
//  BleTransport
//
//  Created by NovaShieldWallet 2026.
//  Tests for error types and their properties.
//

import XCTest
@testable import BleTransport

final class ErrorTests: XCTestCase {
    
    // MARK: - BleTransportError
    
    func testAllBleTransportErrorsHaveDescriptions() {
        let errors: [BleTransportError] = [
            .pendingActionOnDevice,
            .userRefusedOnDevice,
            .scanningTimedOut,
            .bluetoothNotAvailable,
            .connectError(description: "test"),
            .currentConnectedError(description: "test"),
            .writeError(description: "test"),
            .readError(description: "test"),
            .listenError(description: "test"),
            .scanError(description: "test"),
            .pairingError(description: "test"),
            .lowerLevelError(description: "test"),
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) description should not be empty")
        }
    }
    
    func testAllBleTransportErrorsHaveIDs() {
        let errorsWithIDs: [BleTransportError] = [
            .pendingActionOnDevice,
            .scanningTimedOut,
            .bluetoothNotAvailable,
            .connectError(description: "test"),
            .currentConnectedError(description: "test"),
            .writeError(description: "test"),
            .readError(description: "test"),
            .listenError(description: "test"),
            .scanError(description: "test"),
            .pairingError(description: "test"),
            .lowerLevelError(description: "test"),
        ]
        
        for error in errorsWithIDs {
            XCTAssertNotNil(error.id, "\(error) should have an ID")
        }
    }
    
    func testBleTransportErrorEquality() {
        XCTAssertEqual(BleTransportError.pendingActionOnDevice, .pendingActionOnDevice)
        XCTAssertEqual(BleTransportError.connectError(description: "a"), .connectError(description: "a"))
        XCTAssertNotEqual(BleTransportError.connectError(description: "a"), .connectError(description: "b"))
        XCTAssertNotEqual(BleTransportError.pendingActionOnDevice, .userRefusedOnDevice)
        XCTAssertNotEqual(BleTransportError.connectError(description: "a"), .writeError(description: "a"))
    }
    
    func testSpecificErrorIDs() {
        XCTAssertEqual(BleTransportError.pendingActionOnDevice.id, "TransportRaceCondition")
        XCTAssertEqual(BleTransportError.scanningTimedOut.id, "ListenTimeout")
        XCTAssertEqual(BleTransportError.bluetoothNotAvailable.id, "BluetoothNotAvaliable")
        XCTAssertEqual(BleTransportError.connectError(description: "x").id, "ConnectionError")
        XCTAssertEqual(BleTransportError.pairingError(description: "x").id, "PairError")
    }
    
    // MARK: - BleStatusError
    
    func testAllBleStatusErrorsHaveDescriptions() {
        let errors: [BleStatusError] = [
            .userRejected(status: "6985"),
            .appNotAvailableInDevice(status: "6984"),
            .formatNotSupported(status: "0000"),
            .couldNotParseResponseData(status: "0000"),
            .unknown(status: "FFFF"),
            .noStatus,
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have a description")
        }
    }
    
    func testBleStatusErrorStatus() {
        XCTAssertEqual(BleStatusError.userRejected(status: "6985").status, "6985")
        XCTAssertEqual(BleStatusError.unknown(status: "FFFF").status, "FFFF")
        XCTAssertNil(BleStatusError.noStatus.status)
    }
    
    func testBleStatusErrorHashable() {
        var set = Set<BleStatusError>()
        set.insert(.userRejected(status: "6985"))
        set.insert(.userRejected(status: "6985"))
        XCTAssertEqual(set.count, 1, "Identical errors should hash to the same value")
        
        set.insert(.unknown(status: "FFFF"))
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - AppInfo
    
    func testAppInfoEquality() {
        let a = AppInfo(name: "Bitcoin", version: "2.1.0")
        let b = AppInfo(name: "Bitcoin", version: "2.1.0")
        let c = AppInfo(name: "Ethereum", version: "1.0.0")
        
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
