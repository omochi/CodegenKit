// swift-tools-version: 6.0

import PackageDescription

let defaultSwiftSyntaxVersionRange: Range<Version> = "600.0.0"..<"999.0.0"

func parseVersionRange(_ string: String) -> Range<Version>? {
    let parts = string.split(separator: "..<", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let lowerBound = Version(parts[0]),
          let upperBound = Version(parts[1]) else { return nil }
    return lowerBound..<upperBound
}

func swiftSyntaxVersionRange() -> Range<Version> {
    let key = "CODEGENKIT_SWIFTSYNTAX_VERSION"

    guard let versionString = Context.environment[key] else {
        return defaultSwiftSyntaxVersionRange
    }

    let rangeParts = versionString.split(separator: "..<", maxSplits: 1).map(String.init)
    guard
        rangeParts.count == 2,
        let lowerBound = Version(rangeParts[0]),
        let upperBound = Version(rangeParts[1])
    else {
        fatalError("Invalid \(key): \(versionString)")
    }

    return lowerBound..<upperBound
}

let package = Package(
    name: "CodegenKit",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CodegenKit", targets: ["CodegenKit"]),
        .library(name: "CodeTemplateModule", targets: ["CodeTemplateModule"]),
        .plugin(name: "CodegenKitPlugin", targets: ["CodegenKitPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", swiftSyntaxVersionRange()),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "CodeTemplateModule",
            dependencies: []
        ),
        .target(
            name: "CodegenKit",
            dependencies: [
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
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
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
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
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .target(name: "CodegenKit"),
                .target(name: "CodegenKitCLI")
            ]
        )
    ]
)
