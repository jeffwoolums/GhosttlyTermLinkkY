// swift-tools-version: 5.10

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
            path: "GhosttlyTermLinkkY/Sources",
            resources: [
                .process("../Resources/Assets.xcassets"),
                .copy("../Resources/Info.plist")
            ]
        ),
    ]
)
