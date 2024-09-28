// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "integration_test",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "integration-test", targets: ["integration_test"]),
    ],
    targets: [
        .target(
            name: "integration_test",
            resources: [
                .process("Resources"),
            ],
            cSettings: [
                .headerSearchPath("include/integration_test"),
            ]
        ),
    ]
)
