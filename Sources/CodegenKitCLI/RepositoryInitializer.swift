import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKit

public struct RepositoryInitializer {
    public init(
        directory: URL,
        formatConfiguration: SwiftFormatConfiguration.Configuration = Self.defaultFormatConfiguration
    ) {
        self.directory = directory
        self.formatConfiguration = formatConfiguration
        self.fileManager = .default
    }

    public var directory: URL
    public var formatConfiguration: SwiftFormatConfiguration.Configuration

    public static var defaultFormatConfiguration: SwiftFormatConfiguration.Configuration {
        var c = Configuration()
        c.lineLength = 10000
        c.indentation = .spaces(4)
        return c
    }

    private var fileManager: FileManager

    private var codegenKitURL = "https://github.com/omochi/CodegenKit"
    private var codegenKitVersion = "1.2.0"
    private var executableName = "codegen"
    private var pluginName = "CodegenPlugin"

    public func run() throws {
        guard fileManager.directoryExists(atPath: directory.path) else {
            throw MessageError("no directory: \(directory.relativePath)")
        }

        var manifesto = try ManifestoCode(
            fileManager: fileManager,
            formatConfiguration: formatConfiguration,
            file: directory.appendingPathComponent("Package.swift")
        )
        let originalManifesto = manifesto

        try addCodegenKit(manifesto: &manifesto)
        try addExecutable(manifesto: &manifesto)
        try addPlugin(manifesto: &manifesto)

        if manifesto.source != originalManifesto.source {
            try manifesto.format()
            try manifesto.write()
        }
    }

    private func addCodegenKit(manifesto: inout ManifestoCode) throws {
        if let _ = try manifesto.dependency(url: codegenKitURL) {
            return
        }

        print("add CodegenKit dependency")

        try manifesto.addDependency(url: codegenKitURL, version: codegenKitVersion)
    }

    private func addExecutable(manifesto: inout ManifestoCode) throws {
        if let _ = try manifesto.target(name: executableName) {
            return
        }

        print("add \(executableName) executable")

        try manifesto.addExecutable(executableName: executableName)
        try createExecutableDirectory()
    }

    private func createExecutableDirectory() throws {
        let dir = self.directory.appendingPathComponent("Sources/\(executableName)")
        if fileManager.directoryExists(atPath: dir.path) {
            return
        }

        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let source = """
import Foundation
import CodegenKit

let runner = CodegenRunner(renderers: [
    // ** add your renderers here **
])
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try runner.run(directories: [dir])
"""
        let file = dir.appendingPathComponent("main.swift")
        try source.write(to: file, atomically: true, encoding: .utf8)
    }

    private func addPlugin(manifesto: inout ManifestoCode) throws {
        if let _ = try manifesto.target(name: pluginName) {
            return
        }

        print("add \(pluginName) plugin")

        try manifesto.addPlugin(executableName: executableName, pluginName: pluginName)
        try createPluginDirectory()
    }

    private func createPluginDirectory() throws {
        let dir = self.directory.appendingPathComponent("Plugins/\(pluginName)")
        if fileManager.directoryExists(atPath: dir.path) {
            return
        }

        let builder = PluginDirectoryBuilder(
            fileManager: fileManager,
            dir: dir,
            executableName: executableName,
            pluginName: pluginName
        )
        try builder.build()
    }
}
