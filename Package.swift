// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CodegenKit",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CodegenKit", targets: ["CodegenKit"]),
        .library(name: "CodeTemplateModule", targets: ["CodeTemplateModule"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-format", exact: "0.50700.1")
    ],
    targets: [
        .target(
            name: "CodeTemplateModule",
            dependencies: []
        ),
        .target(
            name: "CodegenKit",
            dependencies: [
                .product(name: "SwiftFormat", package: "swift-format"),
                .target(name: "CodeTemplateModule")
            ]
        ),
        .testTarget(
            name: "CodegenKitTests",
            dependencies: ["CodegenKit"]
        ),
    ]
)
