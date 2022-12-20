struct ExampleManifesto: CustomStringConvertible {
    var hasCodegen: Bool = false
    var hasPlugin: Bool = false

    var description: String {
        var lines: [String] = []

        lines.append("""
// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftTypeReader",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftTypeReader",
            targets: ["SwiftTypeReader"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", exact: "0.50700.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.1.3"),
    ],
    targets: [
"""
        )

        if hasCodegen {
            lines.append("""
        .executableTarget(
            name: "codegen",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        ),
"""
            )
        }

        if hasPlugin {
            lines.append("""
        .plugin(
            name: "CodegenPlugin",
            capability: .command(
                intent: .custom(verb: "codegen", description: "codegen"),
                permissions: [.writeToPackageDirectory(reason: "codegen")]
            ),
            dependencies: [
                .target(name: "codegen")
            ]
        ),
"""
            )
        }

        lines.append("""
        .target(
            name: "SwiftTypeReader",
            dependencies: [
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"]
        ),
    ]
)

"""
        )

        return lines.joined(separator: "\n")
    }
}
