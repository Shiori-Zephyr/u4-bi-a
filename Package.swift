// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "U4BIA",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "U4BIA",
            path: "."
        )
    ]
)
