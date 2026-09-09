// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SubSenseCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SubSenseCore", targets: ["SubSenseCore"])],
    targets: [
        .target(name: "SubSenseCore"),
        .testTarget(name: "SubSenseCoreTests", dependencies: ["SubSenseCore"])
    ]
)
