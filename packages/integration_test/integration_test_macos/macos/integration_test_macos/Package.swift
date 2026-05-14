// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "integration_test_macos",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        .library(name: "integration-test-macos", targets: ["integration_test_macos"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "integration_test_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
