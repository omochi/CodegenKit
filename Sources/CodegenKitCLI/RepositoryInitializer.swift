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
        try manifesto.addPluginIfNone(executableName: executableName, pluginName: pluginName)

        if manifesto.source != originalManifesto.source {
            try manifesto.format()
            try manifesto.write()
        }
    }
}
