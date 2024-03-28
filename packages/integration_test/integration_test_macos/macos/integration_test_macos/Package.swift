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
        .package(name: "FlutterFramework", path: "FLUTTER_PATH"),
    ],
    targets: [
        .target(
            name: "integration_test_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
