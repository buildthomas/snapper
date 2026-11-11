// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snapper",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Snapper", targets: ["Snapper"]),
    ],
    targets: [
        // Pure logic (zones, snap rules, geometry), no AppKit: unit tested on CI.
        .target(name: "SnapperCore"),
        .executableTarget(name: "Snapper", dependencies: ["SnapperCore"]),
        .testTarget(name: "SnapperCoreTests", dependencies: ["SnapperCore"]),
    ]
)
