import Foundation
import ArgumentParser
import CodegenKit

public func main() {
    CodegenKitCommand.main()
}

struct CodegenKitCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "codegen-kit",
        abstract: "CodegenKit CLI tool",
        version: CodegenKit.Module.version,
        subcommands: [
            InitCommand.self
        ]
    )

    init() {}
}

struct InitCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize codegen"
    )

    init() {}

    mutating func run() throws {
        let initializer = RepositoryInitializer(directory: URL(fileURLWithPath: "."))
        try initializer.run()
    }
}
