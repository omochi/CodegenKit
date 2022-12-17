// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CodegenKit",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CodegenKit", targets: ["CodegenKit"]),
        .library(name: "TemplateModule", targets: ["TemplateModule"]),
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/CodeTemplate", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-format", exact: "0.50700.1")
    ],
    targets: [
        .target(
            name: "TemplateModule",
            dependencies: []
        ),
        .target(
            name: "CodegenKit",
            dependencies: [
                .product(name: "SwiftFormat", package: "swift-format"),
                .target(name: "TemplateModule")
            ]
        ),
        .testTarget(
            name: "CodegenKitTests",
            dependencies: ["CodegenKit"]
        ),
    ]
)
