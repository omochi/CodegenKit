import XCTest
import CodegenKitCLI

final class RepositoryInitializerTests: XCTestCase {
    func testEmpty() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: try ExampleManifesto().render()
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            try ExampleManifesto(hasCodegenKit: true, hasExecutable: true, hasPlugin: true).render()
        )
    }

    func testEmptyWithOthers() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: try ExampleManifesto(hasOtherDependencies: true, hasOtherTargets: true).render()
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            try ExampleManifesto(
                hasOtherDependencies: true, hasCodegenKit: true,
                hasOtherTargets: true, hasExecutable: true, hasPlugin: true
            ).render()
        )
    }

    func testHasExecutable() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: try ExampleManifesto(hasCodegenKit: true, hasExecutable: true).render()
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            try ExampleManifesto(hasCodegenKit: true, hasExecutable: true, hasPlugin: true).render()
        )
    }

    func testHasExecutableWithOthers() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: try ExampleManifesto(
                hasOtherDependencies: true, hasCodegenKit: true,
                hasOtherTargets: true, hasExecutable: true
            ).render()
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            try ExampleManifesto(
                hasOtherDependencies: true, hasCodegenKit: true,
                hasOtherTargets: true, hasExecutable: true, hasPlugin: true
            ).render()
        )
    }

    func testAlreadyInit() throws {
        let w = WorkspaceBuilder()
        try w.addFile(
            path: "SwiftTypeReader/Package.swift",
            string: try ExampleManifesto(hasCodegenKit: true, hasExecutable: true, hasPlugin: true).render()
        )
        let initializer = RepositoryInitializer(directory: w.path("SwiftTypeReader"))
        try initializer.run()

        XCTAssertEqual(
            try String(contentsOf: w.path("SwiftTypeReader/Package.swift")),
            try ExampleManifesto(hasCodegenKit: true, hasExecutable: true, hasPlugin: true).render()
        )
    }
}

