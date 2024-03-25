// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "integration_test_macos",
    platforms: [
        .macOS("10.14"),
    ],
    products: [
        .library(name: "integration_test_macos", targets: ["integration_test_macos"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "integration_test_macos",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
