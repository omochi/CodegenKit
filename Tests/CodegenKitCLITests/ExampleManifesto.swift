import Foundation
import SwiftOperators
import SwiftSyntax
import SwiftParser
import SwiftFormat
import CodegenKitCLI

struct ExampleManifesto {
    var formatConfiguration: SwiftFormat.Configuration = RepositoryInitializer.defaultFormatConfiguration

    var hasDefaultLocalization: Bool = false
    var hasPlatforms: Bool = false
    var hasOtherDependencies: Bool = false
    var hasCodegenKit: Bool = false
    var hasOtherTargets: Bool = false
    var hasExecutable: Bool = false
    var hasPlugin: Bool = false

    func render() throws -> String {
        var lines: [String] = []

        lines.append("""
// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftTypeReader",
"""
        )

        if hasDefaultLocalization {
            lines.append("""
    defaultLocalization: "ja",
"""
            )
        }

        if hasPlatforms {
            lines.append("""
    platforms: [.macOS(.v10_15)],
"""
            )
        }

        lines.append("""
    products: [],
    dependencies: [
"""
        )

        if hasOtherDependencies {
            lines.append("""
        .package(url: "https://github.com/apple/swift-syntax", exact: "0.50700.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),
"""
            )
        }

        if hasCodegenKit {
            lines.append("""
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.2.2"),
""")
        }

        lines.append("""
    ],
    targets: [
"""
        )

        if hasExecutable {
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
                intent: .custom(
                    verb: "codegen",
                    description: "Generate code"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Write generated code")
                ]
            ),
            dependencies: [
                .target(name: "codegen")
            ]
        ),
"""
            )
        }

        if hasOtherTargets {
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
"""
            )
        }

        lines.append("""
    ]
)

"""
        )

        return try format(source: lines.joined(separator: "\n"))
    }

    private func format(source: String) throws -> String {
        let file = URL(fileURLWithPath: "Package.swift")
        let syntax = Parser.parse(source: source)
        let formatter = SwiftFormatter(configuration: formatConfiguration)
        var out = ""
        try formatter.format(
            syntax: syntax, source: source, operatorTable: OperatorTable(),
            assumingFileURL: file, selection: .infinite, to: &out
        )
        return out
    }
}
