import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKit

struct ManifestoCode {
    init(
        fileManager: FileManager,
        file: URL
    ) throws {
        guard fileManager.fileExists(atPath: file.path) else {
            throw MessageError("no manifesto file: \(file.relativePath)")
        }
        self.fileManager = fileManager
        self.file = file
        self.source = try String(contentsOf: file)
    }

    var fileManager: FileManager
    var file: URL
    var source: String

    mutating func format() throws {
        let syntax = try parse()
        var c = Configuration()
        c.lineLength = 10000
        c.indentation = .spaces(4)
        let formatter = SwiftFormatter(configuration: c)
        var out = ""
        try formatter.format(syntax: syntax, assumingFileURL: file, to: &out)
        self.source = out
    }

    func write() throws {
        try source.write(to: file, atomically: true, encoding: .utf8)
    }

    private func parse() throws -> SourceFileSyntax {
        return try SyntaxParser.parse(source: source, filenameForDiagnostics: file.lastPathComponent)
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


    func targetsArray() throws -> ArrayExprSyntax {
        let syntax = try self.parse()
        let packageCall = try self.packageCall(source: syntax)
        return try self.targetsArray(packageCall: packageCall)
    }

    func target(name: String) throws -> ArrayElementSyntax? {
        return try targetsArray().elements.first {
            targetName($0) == name
        }
    }

    func targetName(_ target: ArrayElementSyntax) -> String? {
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

    mutating func addExecutable(
        executableName: String
    ) throws {
        let targets = try self.targetsArray()

        let position = try targets.leftSquare.endPosition.samePosition(in: source)

        let patch = """
        .executableTarget(
            name: "\(executableName)",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        ),
        """
        self.source.insert(contentsOf: "\n" + patch, at: position)
    }

    mutating func addPlugin(
        executableName: String,
        pluginName: String
    ) throws {
        let targets = try self.targetsArray()

        guard let executableTarget = targets.elements.first(where: {
            targetName($0) == executableName
        }) else {
            throw NoneError(name: "executable target")
        }

        let position = try executableTarget.endPosition.samePosition(in: source)

        let patch = """
        .plugin(
            name: "\(pluginName)",
            capability: .command(
                intent: .custom(
                    verb: "\(executableName)",
                    description: "Generate code"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Write generated code")
                ]
            ),
            dependencies: [
                .target(name: "\(executableName)")
            ]
        ),
        """
        self.source.insert(contentsOf: "\n" + patch, at: position)
    }

}
