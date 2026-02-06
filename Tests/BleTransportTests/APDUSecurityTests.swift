//
//  APDUSecurityTests.swift
//  BleTransport
//
//  Created by NovaShieldWallet 2026.
//  Security-focused tests for APDU parsing and data handling.
//

import XCTest
@testable import BleTransport

final class APDUSecurityTests: XCTestCase {
    
    // MARK: - Hex Parsing Safety
    
    func testHexToBytesReturnsEmptyForOddLength() {
        let result = APDU.hexToBytes("abc")
        XCTAssertTrue(result.isEmpty, "Odd-length hex strings should return empty array")
    }
    
    func testHexToBytesReturnsEmptyForInvalidChars() {
        let result = APDU.hexToBytes("ZZZZ")
        XCTAssertTrue(result.isEmpty, "Non-hex characters should return empty array")
    }
    
    func testHexToBytesHandlesEmptyString() {
        let result = APDU.hexToBytes("")
        XCTAssertTrue(result.isEmpty)
    }
    
    func testHexToBytesCorrectParsing() {
        let result = APDU.hexToBytes("deadbeef")
        XCTAssertEqual(result, [0xde, 0xad, 0xbe, 0xef])
    }
    
    func testHexToBytesUppercase() {
        let result = APDU.hexToBytes("DEADBEEF")
        XCTAssertEqual(result, [0xde, 0xad, 0xbe, 0xef])
    }
    
    func testHexToBytesMixedCase() {
        let result = APDU.hexToBytes("DeAdBeEf")
        XCTAssertEqual(result, [0xde, 0xad, 0xbe, 0xef])
    }
    
    func testHexToBytesDoesNotCrashOnMalformedInput() {
        // Previously this would force-unwrap and crash
        let inputs = ["GG", "0G", "G0", "  ", "0x01", "\n\n", "🔥🔥"]
        for input in inputs {
            let result = APDU.hexToBytes(input)
            XCTAssertTrue(result.isEmpty, "Should safely return empty for: \(input)")
        }
    }
    
    // MARK: - String Extension Safety
    
    func testIsValidHexStringWithValidInput() {
        XCTAssertTrue("abcd".isValidHexString)
        XCTAssertTrue("0123456789abcdef".isValidHexString)
        XCTAssertTrue("ABCDEF".isValidHexString)
    }
    
    func testIsValidHexStringRejectsOddLength() {
        XCTAssertFalse("abc".isValidHexString, "Odd length should be invalid")
    }
    
    func testIsValidHexStringRejectsEmpty() {
        XCTAssertFalse("".isValidHexString, "Empty string should be invalid")
    }
    
    func testIsValidHexStringRejectsNonHex() {
        XCTAssertFalse("ghij".isValidHexString)
        XCTAssertFalse("0xab".isValidHexString) // 'x' is not hex
    }
    
    func testHexToUInt8ArrayConsistency() {
        let hex = "e0d8000007426974636f696e"
        let fromString = hex.hexToUInt8Array()
        let fromAPDU = APDU.hexToBytes(hex)
        XCTAssertEqual(fromString, fromAPDU, "Both methods should produce identical results")
    }
    
    // MARK: - APDU Construction Safety
    
    func testAPDURawInitWithInvalidHexProducesEmptyData() {
        let apdu = APDU(raw: "not-valid-hex!")
        XCTAssertTrue(apdu.data.isEmpty)
        XCTAssertTrue(apdu.isEmpty)
    }
    
    func testAPDUNextOnEmptyDoesNotCrash() {
        let apdu = APDU(data: [])
        apdu.next() // Should not crash
        XCTAssertTrue(apdu.isEmpty)
    }
    
    func testAPDUToBluetoothDataOnEmptyReturnsEmptyData() {
        let apdu = APDU(data: [])
        let data = apdu.toBluetoothData()
        XCTAssertTrue(data.isEmpty)
    }
    
    func testAPDUPreventChunkingBypassesFraming() {
        let apdu = APDU(data: [0x08, 0x00, 0x00, 0x00, 0x00], preventChunking: true)
        XCTAssertEqual(apdu.chunks.count, 1)
        // The chunk should be the raw data, not framed
        XCTAssertEqual(apdu.chunks.first, Data([0x08, 0x00, 0x00, 0x00, 0x00]))
    }
    
    // MARK: - Data Hex Encoding
    
    func testDataHexEncodedStringLowercase() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(data.hexEncodedString(), "deadbeef")
    }
    
    func testDataHexEncodedStringUppercase() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(data.hexEncodedString(uppercase: true), "DEADBEEF")
    }
    
    func testEmptyDataHexEncodedString() {
        XCTAssertEqual(Data().hexEncodedString(), "")
    }
    
    // MARK: - UInt8 Array Hex Encoding
    
    func testBytesToHexWithSpacing() {
        let bytes: [UInt8] = [0xAB, 0xCD]
        XCTAssertEqual(bytes.bytesToHex(spacing: " "), "AB CD")
    }
    
    func testBytesToHexWithoutSpacing() {
        let bytes: [UInt8] = [0xAB, 0xCD]
        XCTAssertEqual(bytes.bytesToHex(), "ABCD")
    }
    
    // MARK: - Chunking Edge Cases
    
    func testChunkAPDUWithSingleByte() {
        let chunks = APDU.chunkAPDU(data: Data([0xFF]), mtuSize: 153)
        XCTAssertEqual(chunks.count, 1)
        // Verify first byte is tag 0x05
        XCTAssertEqual(chunks.first?.first, 0x05)
    }
    
    func testChunkAPDUWithEmptyData() {
        let chunks = APDU.chunkAPDU(data: Data(), mtuSize: 153)
        XCTAssertTrue(chunks.isEmpty)
    }
    
    func testChunkAPDUFrameIndexIncrementsCorrectly() {
        // Create data large enough for multiple frames
        let data = Data(repeating: 0xAA, count: 500)
        let chunks = APDU.chunkAPDU(data: data, mtuSize: 153)
        
        for (index, chunk) in chunks.enumerated() {
            let bytes = Array(chunk)
            // Frame index is bytes 1-2 (big-endian UInt16)
            let frameIndex = Int(bytes[1]) * 256 + Int(bytes[2])
            XCTAssertEqual(frameIndex, index, "Frame \(index) has incorrect frame index \(frameIndex)")
        }
    }
    
    func testChunkAPDUFirstFrameContainsSize() {
        let data = Data(repeating: 0xBB, count: 100)
        let chunks = APDU.chunkAPDU(data: data, mtuSize: 153)
        
        guard let firstChunk = chunks.first else {
            XCTFail("Expected at least one chunk")
            return
        }
        
        let bytes = Array(firstChunk)
        // Size is bytes 3-4 (big-endian UInt16) in first frame only
        let encodedSize = Int(bytes[3]) * 256 + Int(bytes[4])
        XCTAssertEqual(encodedSize, 100, "First frame should encode the total size")
    }
    
    func testChunkAPDUSmallMTU() {
        // Test with very small MTU to ensure it doesn't crash
        let data = Data(repeating: 0xCC, count: 20)
        let chunks = APDU.chunkAPDU(data: data, mtuSize: 10)
        
        XCTAssertTrue(chunks.count > 1, "Small MTU should produce multiple chunks")
        
        // Verify all data is accounted for
        var totalPayload = 0
        for (index, chunk) in chunks.enumerated() {
            let overhead = index == 0 ? 5 : 3
            totalPayload += chunk.count - overhead
        }
        XCTAssertEqual(totalPayload, 20, "All data bytes should be present across chunks")
    }
    
    // MARK: - Bluetooth Data Round-trip
    
    func testBluetoothDataInitCreatesValidAPDU() throws {
        let originalData = Data([0x01, 0x02, 0x03])
        let apdu = try APDU(bluetoothData: originalData)
        XCTAssertEqual(apdu.data, originalData)
    }
    
    func testInferMTUAPDU() {
        let mtuAPDU = APDU.inferMTU
        XCTAssertEqual(mtuAPDU.data, Data([0x08, 0x00, 0x00, 0x00, 0x00]))
        // inferMTU uses preventChunking, so single chunk = raw data
        XCTAssertEqual(mtuAPDU.chunks.count, 1)
    }
}
