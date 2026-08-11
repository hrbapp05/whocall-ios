// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WhocallCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Whocall", targets: ["Whocall"])
    ],
    targets: [
        .target(
            name: "Whocall",
            path: "Whocall/Core/Networking"
        ),
        .testTarget(
            name: "WhocallTests",
            dependencies: ["Whocall"],
            path: "WhocallTests"
        )
    ]
)
