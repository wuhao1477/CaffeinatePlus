// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CaffeinatePlus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CaffeinatePlus",
            targets: ["CaffeinatePlus"]
        )
    ],
    dependencies: [
        // 添加依赖（如果需要）
    ],
    targets: [
        .executableTarget(
            name: "CaffeinatePlus",
            dependencies: [],
            path: "Sources",
            exclude: [
                "Resources"
            ]
        ),
        .testTarget(
            name: "CaffeinatePlusTests",
            dependencies: ["CaffeinatePlus"],
            path: "Tests"
        )
    ]
)
