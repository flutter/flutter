// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "integration_test_macos",
    platforms: [
        .macOS("10.14"),
    ],
    products: [
        .library(name: "integration-test-macos", targets: ["integration_test_macos"]),
    ],
    targets: [
        .target(
            name: "integration_test_macos",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
