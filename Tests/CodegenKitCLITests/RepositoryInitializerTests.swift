import XCTest
import CodegenKitCLI

final class RepositoryInitializerTests: XCTestCase {
    func testEmpty() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: ExampleManifesto().description
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            ExampleManifesto(hasExecutable: true, hasPlugin: true).description
        )
    }

    func testHasExecutable() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: ExampleManifesto(hasExecutable: true).description
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            ExampleManifesto(hasExecutable: true, hasPlugin: true).description
        )
    }

    func testHasExexutableAndPlugin() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: ExampleManifesto(hasExecutable: true, hasPlugin: true).description
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            ExampleManifesto(hasExecutable: true, hasPlugin: true).description
        )
    }
}

