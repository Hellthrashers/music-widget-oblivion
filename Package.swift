// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MusicWidget",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "MusicWidget",
            path: "Sources/MusicWidget"
        )
    ]
)
