import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKitCLI

struct ExampleManifesto {
    var formatConfiguration: SwiftFormatConfiguration.Configuration = RepositoryInitializer.defaultFormatConfiguration
    
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
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.2.0"),
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
        let syntax = try SyntaxParser.parse(source: source, filenameForDiagnostics: file.lastPathComponent)
        let formatter = SwiftFormatter(configuration: formatConfiguration)
        var out = ""
        try formatter.format(syntax: syntax, assumingFileURL: file, to: &out)
        return out
    }
}
