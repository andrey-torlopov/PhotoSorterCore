// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PhotoSorterCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "PhotoSorterCore",
            targets: ["PhotoSorterCore"]
        ),
    ],
    targets: [
        .target(
            name: "PhotoSorterCore",
            dependencies: []
        ),
        .testTarget(
            name: "PhotoSorterCoreTests",
            dependencies: ["PhotoSorterCore"]
        ),
    ]
)
