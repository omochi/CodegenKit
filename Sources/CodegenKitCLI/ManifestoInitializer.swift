import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder
import SwiftFormat
import SwiftFormatConfiguration
import CodegenKit

public struct ManifestoInitializer {
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
        print(file)

        let oldManifesto = try SyntaxParser.parse(file)
        let newManifesto = try modifyPackageCall(manifesto: oldManifesto) { (packageCall) in
            return try modifyTargetsArray(packageCall: packageCall) { (targets) in
                return processTargetArray(targets: targets)
            }
        }
        if oldManifesto != newManifesto {
            let source = newManifesto.description
//            let source = try self.format(syntax: newManifesto, file: file)
            try source.write(to: file, atomically: true, encoding: .utf8)
        }

    }

    private func format(syntax: SourceFileSyntax, file: URL) throws -> String {
        var c = Configuration()
        c.lineLength = 10000
        c.indentation = .spaces(4)
        let formatter = SwiftFormatter(configuration: c)
        var out = ""
        try formatter.format(syntax: syntax, assumingFileURL: file, to: &out)
        return out
    }

    private func modifyPackageCall(
        manifesto: SourceFileSyntax,
        modify: @escaping (FunctionCallExprSyntax) throws -> FunctionCallExprSyntax
    ) throws -> SourceFileSyntax {
        final class Visitor: SyntaxRewriter {
            init(modify: @escaping (FunctionCallExprSyntax) throws -> FunctionCallExprSyntax) {
                self.modify = modify
            }

            var modify: (FunctionCallExprSyntax) throws -> FunctionCallExprSyntax
            var target: FunctionCallExprSyntax? = nil
            var error: Error? = nil

            override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
                guard target == nil else { return ExprSyntax(node) }

                if let ident = node.calledExpression.as(IdentifierExprSyntax.self),
                   ident.identifier.text == "Package"
                {
                    self.target = node
                    do {
                        let node = try self.modify(node)
                        return ExprSyntax(node)
                    } catch {
                        self.error = error
                    }
                }

                return ExprSyntax(node)
            }
        }

        let v = Visitor(modify: modify)
        let result = v.visit(manifesto)
        if v.target == nil {
            throw MessageError("no Package call found")
        }
        return SourceFileSyntax(result)!
    }

    private func modifyTargetsArray(
        packageCall: FunctionCallExprSyntax,
        modify: (ArrayExprSyntax) -> ArrayExprSyntax
    ) throws -> FunctionCallExprSyntax {
        var found = false
        var args = packageCall.argumentList
        for (index, arg) in args.enumerated() {
            var arg = arg
            guard !found else { break }

            if arg.label?.text == "targets",
               var array = arg.expression.as(ArrayExprSyntax.self)
            {
                found = true
                array = modify(array)
                arg = arg.withExpression(ExprSyntax(array))
                args = args.replacing(childAt: index, with: arg)
            }
        }
        if !found {
            throw MessageError("no targets")
        }

        return packageCall.withArgumentList(args)
    }

    private func processTargetArray(targets: ArrayExprSyntax) -> ArrayExprSyntax {
        var elements = targets.elements
        elements = addExecutableTargetIfNone(elements: elements)
        return targets.withElements(elements)
    }

    private func addExecutableTargetIfNone(elements: ArrayElementListSyntax) -> ArrayElementListSyntax {
        if elements.contains(where: { targetName($0) == executableName }) {
            return elements
        }

        print("add codegen executable")

        var elements = elements

        let targetExpr = FunctionCallExpr(
            calledExpression: MemberAccessExpr(
                dot: .prefixPeriod.withLeadingTrivia(.newlines(1)),
                name: TokenSyntax.identifier("executableTarget")
            ),
            leftParen: .leftParen.withTrailingTrivia(.newlines(1)),
            argumentList: TupleExprElementList([
                TupleExprElement(
                    label: .identifier("name"),
                    colon: .colon,
                    expression: stringLiteral(executableName),
                    trailingComma: .comma.withTrailingTrivia(.newlines(1))
                ),
                TupleExprElement(
                    label: .identifier("dependencies"),
                    colon: .colon,
                    expression: ArrayExpr(
                        leftSquare: .leftSquareBracket.withTrailingTrivia(.newlines(1)),
                        elements: ArrayElementList([
                            ArrayElement(
                                expression: FunctionCallExpr(
                                    calledExpression: MemberAccessExpr(
                                        dot: .prefixPeriod, name: .identifier("product")
                                    ),
                                    leftParen: .leftParen,
                                    argumentList: TupleExprElementList([
                                        TupleExprElement(
                                            label: .identifier("name"),
                                            colon: .colon,
                                            expression: stringLiteral("CodegenKit"),
                                            trailingComma: .comma
                                        ),
                                        TupleExprElement(
                                            label: .identifier("package"),
                                            colon: .colon,
                                            expression: stringLiteral("CodegenKit")
                                        )
                                    ]),
                                    rightParen: .rightParen.withTrailingTrivia(.newlines(1))
                                )
                            )
                        ]),
                        rightSquare: .rightSquareBracket.withTrailingTrivia(.newlines(1))
                    )
                )
            ]),
            rightParen: .rightParen
        )

        let newElement = ArrayElementSyntax(
            ArrayElement(expression: targetExpr, trailingComma: .comma)
                .buildSyntax(format: buildFormat)
        )!

        elements = elements.inserting(newElement, at: 0)

        return elements
    }

    private func stringLiteral(_ text: String, newline: Bool = false) -> StringLiteralExpr {
        func closeQuote() -> TokenSyntax {
            var token = TokenSyntax.stringQuote
            if newline {
                token = token.withTrailingTrivia(.newlines(1))
            }
            return token
        }

        return StringLiteralExpr(
            openQuote: .stringQuote,
            segments: StringLiteralSegments([
                StringSegment(content: text)
            ]),
            closeQuote: closeQuote()
        )
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
}
