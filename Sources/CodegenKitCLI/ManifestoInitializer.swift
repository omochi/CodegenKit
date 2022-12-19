import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import CodegenKit

public struct ManifestoInitializer {
    public init(directory: URL) {
        self.directory = directory
        self.fileManager = .default
    }

    public var directory: URL
    private let fileManager: FileManager

    public func run() throws {
        guard fileManager.directoryExists(atPath: directory.path) else {
            throw MessageError("no directory: \(directory.relativePath)")
        }

        let manifestoFile = directory.appendingPathComponent("Package.swift")
        guard fileManager.fileExists(atPath: manifestoFile.path) else {
            throw MessageError("no manifesto file: \(manifestoFile.relativePath)")
        }

        let manifestoSyntax = try SyntaxParser.parse(manifestoFile)

        print(manifestoSyntax)
    }
}
