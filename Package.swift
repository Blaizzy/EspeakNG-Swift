// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EspeakNG-Swift",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(
            name: "ESpeakNG",
            targets: ["ESpeakNGSwift"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "ESpeakNG",
            path: "Frameworks/ESpeakNG.xcframework"
        ),
        .target(
            name: "ESpeakNGSwift",
            dependencies: ["ESpeakNG"],
            path: "Sources/ESpeakNG"
        ),
        .testTarget(
            name: "ESpeakNGTests",
            dependencies: ["ESpeakNGSwift"],
            path: "Tests/ESpeakNGTests"
        ),
    ]
)

