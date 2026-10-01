// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Core",
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    targets: [
        .target(name: "Core"),
        .executableTarget(name: "GenLevels", dependencies: ["Core"]),
        .executableTarget(name: "GenSounds", dependencies: []),
        .executableTarget(name: "Validate", dependencies: ["Core"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ],
    swiftLanguageModes: [.v6]
)
