//
//  ConfigurationTests.swift
//  BleTransport
//
//  Created by NovaShieldWallet 2026.
//  Tests for BLE configuration and device service definitions.
//

import XCTest
import CoreBluetooth
@testable import BleTransport

final class ConfigurationTests: XCTestCase {
    
    // MARK: - Default Configuration
    
    func testDefaultConfigHasFourServices() {
        let config = BleTransportConfiguration.defaultConfig()
        XCTAssertEqual(config.services.count, 4, "Default config should include Nano X, Nano FTS, Stax, and Flex")
    }
    
    func testDefaultConfigContainsNanoX() {
        let config = BleTransportConfiguration.defaultConfig()
        let nanoXUUID = CBUUID(string: "13D63400-2C97-0004-0000-4C6564676572")
        let match = config.serviceMatching(serviceUUID: nanoXUUID)
        XCTAssertNotNil(match, "Default config should contain Nano X service")
    }
    
    func testDefaultConfigContainsNanoFTS() {
        let config = BleTransportConfiguration.defaultConfig()
        let nanoFTSUUID = CBUUID(string: "13D63400-2C97-6004-0000-4C6564676572")
        let match = config.serviceMatching(serviceUUID: nanoFTSUUID)
        XCTAssertNotNil(match, "Default config should contain Nano FTS service")
    }
    
    func testDefaultConfigContainsStax() {
        let config = BleTransportConfiguration.defaultConfig()
        let staxUUID = CBUUID(string: "13D63400-2C97-3004-0000-4C6564676572")
        let match = config.serviceMatching(serviceUUID: staxUUID)
        XCTAssertNotNil(match, "Default config should contain Stax service")
    }
    
    func testDefaultConfigContainsFlex() {
        let config = BleTransportConfiguration.defaultConfig()
        let flexUUID = CBUUID(string: "13D63400-2C97-4004-0000-4C6564676572")
        let match = config.serviceMatching(serviceUUID: flexUUID)
        XCTAssertNotNil(match, "Default config should contain Flex service")
    }
    
    func testServiceMatchingReturnsNilForUnknownUUID() {
        let config = BleTransportConfiguration.defaultConfig()
        let unknownUUID = CBUUID(string: "00000000-0000-0000-0000-000000000000")
        let match = config.serviceMatching(serviceUUID: unknownUUID)
        XCTAssertNil(match, "Unknown UUID should not match any service")
    }
    
    // MARK: - BleService Static Constants
    
    func testNanoXServiceUUIDs() {
        let service = BleService.nanoX
        XCTAssertEqual(service.service.uuid, CBUUID(string: "13D63400-2C97-0004-0000-4C6564676572"))
        XCTAssertEqual(service.notify.uuid, CBUUID(string: "13D63400-2C97-0004-0001-4C6564676572"))
        XCTAssertEqual(service.writeWithResponse.uuid, CBUUID(string: "13D63400-2C97-0004-0002-4C6564676572"))
        XCTAssertEqual(service.writeWithoutResponse.uuid, CBUUID(string: "13D63400-2C97-0004-0003-4C6564676572"))
    }
    
    func testStaxServiceUUIDs() {
        let service = BleService.stax
        XCTAssertEqual(service.service.uuid, CBUUID(string: "13D63400-2C97-3004-0000-4C6564676572"))
    }
    
    func testFlexServiceUUIDs() {
        let service = BleService.flex
        XCTAssertEqual(service.service.uuid, CBUUID(string: "13D63400-2C97-4004-0000-4C6564676572"))
    }
    
    // MARK: - Write Characteristic Selection
    
    func testWriteCharacteristicWithResponse() {
        let service = BleService.nanoX
        let char = service.writeCharacteristic(canWriteWithoutResponse: false)
        XCTAssertEqual(char.uuid, service.writeWithResponse.uuid)
    }
    
    func testWriteCharacteristicWithoutResponse() {
        let service = BleService.nanoX
        let char = service.writeCharacteristic(canWriteWithoutResponse: true)
        XCTAssertEqual(char.uuid, service.writeWithoutResponse.uuid)
    }
    
    // MARK: - Custom Configuration
    
    func testCustomConfigWithSingleService() {
        let customService = BleService(
            serviceUUID: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            notifyUUID: "AAAAAAAA-BBBB-CCCC-DDDD-FFFFFFFFFFFF",
            writeWithResponseUUID: "AAAAAAAA-BBBB-CCCC-DDDD-111111111111",
            writeWithoutResponseUUID: "AAAAAAAA-BBBB-CCCC-DDDD-222222222222"
        )
        
        let config = BleTransportConfiguration(services: [customService])
        XCTAssertEqual(config.services.count, 1)
        
        let match = config.serviceMatching(serviceUUID: CBUUID(string: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"))
        XCTAssertNotNil(match)
    }
    
    // MARK: - Identifier Types
    
    func testPeripheralIdentifierEquality() {
        let uuid = UUID()
        let a = PeripheralIdentifier(uuid: uuid, name: "Nano X")
        let b = PeripheralIdentifier(uuid: uuid, name: "Different Name")
        let c = PeripheralIdentifier(uuid: UUID(), name: "Nano X")
        
        XCTAssertEqual(a, b, "Equality should be based on UUID only")
        XCTAssertNotEqual(a, c, "Different UUIDs should not be equal")
    }
    
    func testPeripheralIdentifierDefaultName() {
        let p = PeripheralIdentifier(uuid: UUID(), name: nil)
        XCTAssertEqual(p.name, "No Name")
    }
    
    func testPeripheralIdentifierDescription() {
        let uuid = UUID()
        let p = PeripheralIdentifier(uuid: uuid, name: "My Nano X")
        XCTAssertTrue(p.description.contains("My Nano X"))
        XCTAssertTrue(p.description.contains(uuid.uuidString))
    }
    
    func testPeripheralIdentifierHashable() {
        let uuid = UUID()
        let a = PeripheralIdentifier(uuid: uuid, name: "A")
        let b = PeripheralIdentifier(uuid: uuid, name: "B")
        
        var set = Set<PeripheralIdentifier>()
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 1, "Same UUID should hash identically")
    }
    
    // MARK: - ServiceIdentifier
    
    func testServiceIdentifierEquality() {
        let a = ServiceIdentifier(uuid: "13D63400-2C97-0004-0000-4C6564676572")
        let b = ServiceIdentifier(uuid: "13D63400-2C97-0004-0000-4C6564676572")
        let c = ServiceIdentifier(uuid: "13D63400-2C97-6004-0000-4C6564676572")
        
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
    
    // MARK: - CharacteristicIdentifier
    
    func testCharacteristicIdentifierEquality() {
        let service = ServiceIdentifier(uuid: "13D63400-2C97-0004-0000-4C6564676572")
        let a = CharacteristicIdentifier(uuid: "13D63400-2C97-0004-0001-4C6564676572", service: service)
        let b = CharacteristicIdentifier(uuid: "13D63400-2C97-0004-0001-4C6564676572", service: service)
        let c = CharacteristicIdentifier(uuid: "13D63400-2C97-0004-0002-4C6564676572", service: service)
        
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
    
    func testCharacteristicIdentifierDescription() {
        let service = ServiceIdentifier(uuid: "13D63400-2C97-0004-0000-4C6564676572")
        let char = CharacteristicIdentifier(uuid: "13D63400-2C97-0004-0001-4C6564676572", service: service)
        
        XCTAssertTrue(char.description.contains("Characteristic:"))
        XCTAssertTrue(char.description.contains("Service:"))
    }
}
