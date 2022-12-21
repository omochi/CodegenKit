import ArgumentParser
import CodegenKit

public struct CodegenKitCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "codegen-kit",
        abstract: "CodegenKit CLI tool",
        version: CodegenKit.Module.version,
        subcommands: [
            InitCommand.self
        ]
    )

    public init() {}
}

public struct InitCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize codegen"
    )

    public init() {}

    public mutating func run() {
        print("init!")
    }
}
