// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GhosttlyTermLinkkY",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "GhosttlyTermLinkkY",
            targets: ["GhosttlyTermLinkkY"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "GhosttlyTermLinkkY",
            dependencies: [],
            path: "GhosttlyTermLinkkY/Sources"
        ),
    ]
)
