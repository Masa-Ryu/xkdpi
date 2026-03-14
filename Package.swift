// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "xkdpi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "xkdpi", targets: ["App"]),
        .library(name: "xkdpiLib", targets: ["xkdpi"]),
    ],
    targets: [
        .target(
            name: "xkdpi",
            path: "Sources/xkdpi"
        ),
        .executableTarget(
            name: "App",
            dependencies: ["xkdpi"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "DisplayTests",
            dependencies: ["xkdpi"],
            path: "Tests/DisplayTests"
        ),
    ]
)
