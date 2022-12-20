import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKit

public struct RepositoryInitializer {
    public init(directory: URL) {
        self.directory = directory
        self.fileManager = .default
        self.buildFormat = Format(indentWidth: 4)
    }

    public var directory: URL
    private var fileManager: FileManager
    private var buildFormat: SwiftSyntaxBuilder.Format
    private var executableName = "codegen"
    private var pluginName = "CodegenPlugin"

    public func run() throws {
        guard fileManager.directoryExists(atPath: directory.path) else {
            throw MessageError("no directory: \(directory.relativePath)")
        }

        var manifesto = try ManifestoCode(
            fileManager: fileManager,
            file: directory.appendingPathComponent("Package.swift")
        )
        let originalManifesto = manifesto

        try manifesto.addExecutableIfNone(executableName: executableName)
        try createExecutableDirectory()
        try manifesto.addPluginIfNone(executableName: executableName, pluginName: pluginName)
        try createPluginDirectory()

        if manifesto.source != originalManifesto.source {
            try manifesto.format()
            try manifesto.write()
        }
    }

    private func createExecutableDirectory() throws {
        let dir = self.directory.appendingPathComponent("Sources/\(executableName)")
        if fileManager.directoryExists(atPath: dir.path) {
            return
        }

        print("create \(executableName) directory")

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

    private func createPluginDirectory() throws {
        let dir = self.directory.appendingPathComponent("Plugins/\(pluginName)")
        if fileManager.directoryExists(atPath: dir.path) {
            return
        }

        print("create \(pluginName) directory")

        let builder = PluginDirectoryBuilder(
            fileManager: fileManager,
            dir: dir,
            executableName: executableName,
            pluginName: pluginName
        )
        try builder.build()
    }
}
