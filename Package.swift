// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LedgerBleTransport",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BleTransport",
            targets: ["BleTransport"]),
    ],
    targets: [
        .target(
            name: "BleTransport",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "BleTransportTests",
            dependencies: ["BleTransport"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
