// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WallerNative",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "WallerNative",
            dependencies: [
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ],
            path: "Sources/WallerNative"
        )
    ]
)
