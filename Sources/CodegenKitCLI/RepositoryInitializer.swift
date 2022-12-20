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

        let file = directory.appendingPathComponent("Package.swift")
        guard fileManager.fileExists(atPath: file.path) else {
            throw MessageError("no manifesto file: \(file.relativePath)")
        }
        print(file.path)

        let originalSource = try String(contentsOf: file)
        var source = originalSource
        source = try addExecutableIfNone(source: source, file: file)
        if source != originalSource {
            source = try self.format(source: source, file: file)
            try source.write(to: file, atomically: true, encoding: .utf8)
        }
    }

    private func parse(source: String, file: URL) throws -> SourceFileSyntax {
        return try SyntaxParser.parse(source: source, filenameForDiagnostics: file.lastPathComponent)
    }

    private func format(source: String, file: URL) throws -> String {
        let syntax = try parse(source: source, file: file)
        var c = Configuration()
        c.lineLength = 10000
        c.indentation = .spaces(4)
        let formatter = SwiftFormatter(configuration: c)
        var out = ""
        try formatter.format(syntax: syntax, assumingFileURL: file, to: &out)
        return out
    }

    private func packageCall(source: SourceFileSyntax) throws -> FunctionCallExprSyntax {
        final class Visitor: SyntaxAnyVisitor {
            var result: FunctionCallExprSyntax? = nil

            override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
                guard result == nil else { return .skipChildren }
                return .visitChildren
            }

            override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
                guard result == nil else { return .skipChildren }

                if let ident = node.calledExpression.as(IdentifierExprSyntax.self),
                   ident.identifier.text == "Package"
                {
                    self.result = node
                    return .skipChildren
                }

                return .visitChildren
            }
        }

        let v = Visitor()
        v.walk(source)
        return try v.result.unwrap("Package call")
    }

    private func targetsArray(packageCall: FunctionCallExprSyntax) throws -> ArrayExprSyntax {
        for arg in packageCall.argumentList {
            if arg.label?.text == "targets",
               let array = arg.expression.as(ArrayExprSyntax.self)
            {
                return array
            }
        }
        throw NoneError(name: "targets array")
    }

    private func targetName(_ target: ArrayElementSyntax) -> String? {
        guard let call = target.expression.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base == nil else { return nil }
        for arg in call.argumentList {
            if arg.label?.text == "name" {
                guard let string = arg.expression.as(StringLiteralExprSyntax.self),
                      string.segments.count == 1,
                      let text = string.segments.first?.as(StringSegmentSyntax.self) else {
                    return nil
                }

                return text.content.text
            }
        }
        return nil
    }

    private func addExecutableIfNone(source: String, file: URL) throws -> String {
        var source = source
        let syntax = try parse(source: source, file: file)
        let packageCall = try self.packageCall(source: syntax)
        let targets = try self.targetsArray(packageCall: packageCall)
        if targets.elements.contains(where: { targetName($0) == executableName }) {
            return source
        }

        print("add \(executableName) executable")

        let position = try targets.leftSquare.endPosition.samePosition(in: source)

        let patch = """
        .executableTarget(
            name: "\(executableName)",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        ),
        """
        source.insert(contentsOf: "\n" + patch, at: position)
        return source
    }
}
