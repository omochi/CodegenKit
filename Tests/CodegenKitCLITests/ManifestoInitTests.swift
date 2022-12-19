import XCTest
import CodegenKitCLI

final class ManifestoInitTests: XCTestCase {
    func testEmpty() throws {
        let w = WorkspaceBuilder()
        try w.addFile(path: "SwiftTypeReader/Package.swift", string: """
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
                .package(url: "https://github.com/omochi/CodegenKit", from: "1.1.3")
            ],
            targets: [
                .target(
                    name: "SwiftTypeReader",
                    dependencies: [
                        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                        .product(name: "Collections", package: "swift-collections")
                    ]
                ),
                .testTarget(
                    name: "SwiftTypeReaderTests",
                    dependencies: ["SwiftTypeReader"]
                )
            ]
        )
        """)

        let initializer = ManifestoInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()
    }
}
