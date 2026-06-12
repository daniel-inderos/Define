// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Define",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Define",
            path: "Sources/Define"
        ),
        .testTarget(
            name: "DefineTests",
            dependencies: ["Define"],
            path: "Tests/DefineTests"
        ),
    ]
)
