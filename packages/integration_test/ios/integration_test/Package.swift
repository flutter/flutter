// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "integration_test",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "integration-test", targets: ["integration_test"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "integration_test",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("Resources"),
            ],
            cSettings: [
                .headerSearchPath("include/integration_test"),
            ]
        ),
    ]
)
