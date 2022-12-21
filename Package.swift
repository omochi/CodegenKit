// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CodegenKit",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "CodegenKit", targets: ["CodegenKit"]),
        .library(name: "CodeTemplateModule", targets: ["CodeTemplateModule"]),
        .plugin(name: "CodegenKitPlugin", targets: ["CodegenKitPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-format", exact: "0.50700.1"),
        .package(url: "https://github.com/apple/swift-syntax", exact: "0.50700.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.4")
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
        .target(
            name: "CodegenKitCLI",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "CodegenKit")
            ]
        ),
        .executableTarget(
            name: "codegen-kit",
            dependencies: [
                .target(name: "CodegenKitCLI")
            ]
        ),
        .plugin(
            name: "CodegenKitPlugin",
            capability: .command(
                intent: .custom(
                    verb: "codegen-kit", description: "Use CodegenKit CLI"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Setup project")
                ]
            ),
            dependencies: [
                .target(name: "codegen-kit")
            ]
        ),
        .testTarget(
            name: "CodegenKitCLITests",
            dependencies: [
                .target(name: "CodegenKitCLI")
            ]
        )
    ]
)
