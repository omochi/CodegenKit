import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKit

struct ManifestoCode {
    init(
        fileManager: FileManager,
        formatConfiguration: SwiftFormatConfiguration.Configuration,
        file: URL
    ) throws {
        guard fileManager.fileExists(atPath: file.path) else {
            throw MessageError("no manifesto file: \(file.relativePath)")
        }
        self.fileManager = fileManager
        self.formatConfiguration = formatConfiguration
        self.file = file
        self.source = try String(contentsOf: file)
    }

    var fileManager: FileManager
    var formatConfiguration: SwiftFormatConfiguration.Configuration
    var file: URL
    var source: String

    mutating func format() throws {
        let syntax = try parse()
        let formatter = SwiftFormatter(configuration: formatConfiguration)
        var out = ""
        try formatter.format(syntax: syntax, assumingFileURL: file, to: &out)
        self.source = out
    }

    func write() throws {
        try source.write(to: file, atomically: true, encoding: .utf8)
    }

    func nameArg() throws -> TupleExprElementSyntax? {
        return try self.nameArg(packageCall: self.packageCall())
    }

    func defaultLocalizationArg() throws -> TupleExprElementSyntax? {
        return try self.defaultLocalizationArg(packageCall: self.packageCall())
    }

    func platformsArg() throws -> TupleExprElementSyntax? {
        return try self.packageCall().arg(name: "platforms")
    }

    func dependenciesArray() throws -> ArrayExprSyntax {
        let packageCall = try self.packageCall()
        return try self.dependenciesArray(packageCall: packageCall)
    }

    func dependency(url: String) throws -> ArrayElementSyntax? {
        return try dependenciesArray().elements.first {
            dependencyURL($0) == url
        }
    }

    func targetsArray() throws -> ArrayExprSyntax {
        let packageCall = try self.packageCall()
        return try self.targetsArray(packageCall: packageCall)
    }

    func target(name: String) throws -> ArrayElementSyntax? {
        return try targetsArray().elements.first {
            targetName($0) == name
        }
    }

    private func parse() throws -> SourceFileSyntax {
        return try SyntaxParser.parse(source: source, filenameForDiagnostics: file.lastPathComponent)
    }

    private func packageCall() throws -> FunctionCallExprSyntax {
        let syntax = try self.parse()
        return try self.packageCall(source: syntax)
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

    private func nameArg(packageCall: FunctionCallExprSyntax) -> TupleExprElementSyntax? {
        return packageCall.arg(name: "name")
    }

    private func defaultLocalizationArg(packageCall: FunctionCallExprSyntax) -> TupleExprElementSyntax? {
        return packageCall.arg(name: "defaultLocalization")
    }

    private func dependenciesArray(packageCall: FunctionCallExprSyntax) throws -> ArrayExprSyntax {
        guard let arg = packageCall.arg(name: "dependencies"),
              let array = arg.expression.as(ArrayExprSyntax.self) else {
            throw NoneError(name: "dependencies array")
        }
        return array
    }

    private func targetsArray(packageCall: FunctionCallExprSyntax) throws -> ArrayExprSyntax {
        guard let arg = packageCall.arg(name: "targets"),
              let array = arg.expression.as(ArrayExprSyntax.self) else {
            throw NoneError(name: "targets array")
        }
        return array
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

    private func dependencyURL(_ dependency: ArrayElementSyntax) -> String? {
        guard let call = dependency.expression.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base == nil,
              let arg = call.arg(name: "url"),
              let string = arg.expression.as(StringLiteralExprSyntax.self),
              string.segments.count == 1,
              let text = string.segments.first?.as(StringSegmentSyntax.self)
        else { return nil }

        return text.content.text
    }

    mutating func addPlatform(
        platform: String
    ) throws {
        let packageCall = try self.packageCall()

        let frontArg: TupleExprElementSyntax = try {
            if let arg = self.defaultLocalizationArg(packageCall: packageCall) {
                return arg
            }
            return try self.nameArg(packageCall: packageCall).unwrap("name")
        }()

        let position = try frontArg.endPosition.samePosition(in: source)

        var patch = """
        platforms: [\(platform)],
        """

        patch = "\n" + patch

        self.source.insert(contentsOf: patch, at: position)
    }

    mutating func addDependency(
        url: String, version: String
    ) throws {
        let dependencies = try self.dependenciesArray()

        let position: String.Index = try {
            if let last = dependencies.elements.last {
                return try last.endPosition.samePosition(in: source)
            }
            return try dependencies.rightSquare.positionAfterSkippingLeadingTrivia.samePosition(in: source)
        }()

        var patch = """
        .package(url: "\(url)", from: "\(version)"),
        """

        patch = "\n" + patch

        self.source.insert(contentsOf: patch, at: position)
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

        var patch = """
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

        patch = "\n" + patch

        if executableTarget.trailingComma == nil {
            patch = "," + patch
        }

        self.source.insert(contentsOf: patch, at: position)
    }

}
