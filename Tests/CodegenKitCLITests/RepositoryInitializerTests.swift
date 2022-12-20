import XCTest
import CodegenKitCLI

final class RepositoryInitializerTests: XCTestCase {
    func testEmpty() throws {
        let w = WorkspaceBuilder()
        try w.addFile(path: "SwiftTypeReader/Package.swift", string: ExampleManifesto().description)
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            ExampleManifesto(hasCodegen: true).description
        )
    }
}

