// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GhosttlyTermLinkkY",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GhosttlyTermLinkkY",
            targets: ["GhosttlyTermLinkkY"]),
    ],
    dependencies: [
        // For production SSH support, add:
        // .package(url: "https://github.com/Lakr233/SwiftCitadel.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GhosttlyTermLinkkY",
            dependencies: [],
            path: "GhosttlyTermLinkkY/Sources"
        ),
    ]
)
