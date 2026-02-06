//
//  APDU.swift
//  BleTransport
//
//  Created by Dante Puglisi on 5/10/22.
//  Security hardened by NovaShieldWallet 2026.
//

import Foundation

/// Represents an Application Protocol Data Unit for Ledger device communication.
///
/// APDUs are automatically chunked into BLE-compatible frames based on the
/// negotiated MTU size. Each frame includes a header tag, frame index, and
/// (for the first frame) the total payload size.
public class APDU: BluetoothSendable, Receivable {
    
    /// The raw APDU data payload.
    public let data: Data
    
    /// The APDU data split into BLE frames smaller than `mtuSize`.
    public private(set) var chunks: [Data] = []
    
    /// The maximum number of bytes (including tag and frame index) per BLE frame.
    /// Updated during MTU negotiation when connecting to a new device.
    ///
    /// - Important: Default value of 153 matches Ledger Nano X specifications.
    nonisolated(unsafe) static var mtuSize: Int = 153
    
    /// Whether all chunks have been consumed/sent.
    public var isEmpty: Bool {
        chunks.isEmpty
    }
    
    /// Special APDU used to negotiate MTU size with the connected device.
    public static let inferMTU = APDU(data: [0x08, 0x00, 0x00, 0x00, 0x00], preventChunking: true)
    
    /// Creates an APDU from raw byte data.
    /// - Parameters:
    ///   - data: The byte array representing the APDU command.
    ///   - preventChunking: If `true`, the data is sent as a single frame without chunking.
    public init(data: [UInt8], preventChunking: Bool = false) {
        let dataReceived = Data(data)
        self.data = dataReceived
        if preventChunking {
            self.chunks = [Data(data)]
        } else {
            self.chunks = Self.chunkAPDU(data: dataReceived, mtuSize: Self.mtuSize)
        }
    }
    
    /// Creates an APDU from a hexadecimal string.
    ///
    /// - Parameter raw: A hex-encoded string (e.g. `"e0d8000007426974636f696e"`).
    ///   Must contain only valid hex characters and have even length.
    ///   Returns an empty APDU if the string is invalid.
    public init(raw: String) {
        guard raw.isValidHexString else {
            self.data = Data()
            return
        }
        let bytes = Self.hexToBytes(raw)
        let dataReceived = Data(bytes)
        self.data = dataReceived
        self.chunks = Self.chunkAPDU(data: dataReceived, mtuSize: Self.mtuSize)
    }
    
    /// Creates an APDU from raw Bluetooth data received from a device.
    required public init(bluetoothData: Data) throws {
        self.data = bluetoothData
        self.chunks = Self.chunkAPDU(data: bluetoothData, mtuSize: Self.mtuSize)
    }
    
    /// Returns the current (first) frame for BLE transmission.
    public func toBluetoothData() -> Data {
        guard let first = chunks.first else {
            return Data()
        }
        return first
    }
    
    /// Advances to the next frame by removing the current one.
    func next() {
        guard !chunks.isEmpty else { return }
        chunks.removeFirst()
    }
    
    /// Splits APDU data into BLE-compatible frames.
    ///
    /// Frame format:
    /// - Byte 0: Tag (0x05 for Ledger devices)
    /// - Bytes 1-2: Frame index (big-endian UInt16)
    /// - Bytes 3-4 (first frame only): Total payload size (big-endian UInt16)
    /// - Remaining bytes: Payload data
    ///
    /// - Parameters:
    ///   - data: The raw APDU data to chunk.
    ///   - mtuSize: The maximum transmission unit size for framing.
    /// - Returns: An array of `Data` frames ready for BLE transmission.
    internal static func chunkAPDU(data: Data, mtuSize: Int) -> [Data] {
        guard !data.isEmpty else { return [] }
        
        let apdu: [UInt8] = Array(data)
        var chunks = [Data]()
        let size = UInt16(clamping: apdu.count)
        
        let head: UInt8 = 0x05 // Tag/Head for Ledger devices
        var offset = 0         // Current position in the payload
        var frameIndex = UInt16(0)
        
        while offset < apdu.count {
            // First frame: 1 (tag) + 2 (index) + 2 (size) = 5 byte overhead
            // Subsequent frames: 1 (tag) + 2 (index) = 3 byte overhead
            let overhead = frameIndex == 0 ? 5 : 3
            let maxPayload = max(mtuSize - overhead, 1)
            
            var frame = Data()
            frame.reserveCapacity(min(mtuSize, apdu.count - offset + overhead))
            
            frame.append(head)
            withUnsafeBytes(of: frameIndex.bigEndian) { frame.append(contentsOf: $0) }
            
            if frameIndex == 0 {
                withUnsafeBytes(of: size.bigEndian) { frame.append(contentsOf: $0) }
            }
            
            let end = min(offset + maxPayload, apdu.count)
            frame.append(contentsOf: apdu[offset..<end])
            
            offset = end
            frameIndex += 1
            chunks.append(frame)
        }
        return chunks
    }
    
    // MARK: - Safe Hex Parsing
    
    /// Safely converts a hex string to a byte array.
    ///
    /// - Parameter hex: A valid hex string with even length.
    /// - Returns: The parsed byte array, or empty array if parsing fails.
    internal static func hexToBytes(_ hex: String) -> [UInt8] {
        guard hex.count % 2 == 0 else { return [] }
        
        var bytes = [UInt8]()
        bytes.reserveCapacity(hex.count / 2)
        
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else {
                return [] // Return empty on any parse failure instead of crashing
            }
            bytes.append(byte)
            index = nextIndex
        }
        return bytes
    }
}

// MARK: - Common APDU Commands

/// Pre-built APDU commands for common Ledger operations.
enum APDUCommands {
    public static let openBitcoin: [APDU] = [APDU(raw: "e0d8000007426974636f696e")]
}

// MARK: - String Extensions

public extension String {
    /// Safely converts a hex string to a `[UInt8]` array.
    ///
    /// Returns an empty array if the string has odd length or contains non-hex characters.
    func hexToUInt8Array() -> [UInt8] {
        return APDU.hexToBytes(self)
    }
    
    /// Whether this string contains only valid hexadecimal characters and has even length.
    var isValidHexString: Bool {
        !isEmpty && count % 2 == 0 && allSatisfy(\.isHexDigit)
    }
}

// MARK: - Data Extensions

public extension Array where Element == UInt8 {
    /// Converts a byte array to a hex string with optional spacing between bytes.
    func bytesToHex(spacing: String = "") -> String {
        map { String(format: "%02X", $0) }.joined(separator: spacing)
    }
}

public extension Data {
    /// Returns a hex-encoded string representation of this data.
    func hexEncodedString(uppercase: Bool = false) -> String {
        let format = uppercase ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
