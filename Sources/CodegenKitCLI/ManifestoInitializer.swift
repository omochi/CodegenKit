import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder
import CodegenKit

public struct ManifestoInitializer {
    public init(directory: URL) {
        self.directory = directory
        self.fileManager = .default
        self.format = Format(indentWidth: 4)
    }

    public var directory: URL
    private var fileManager: FileManager
    private var format: SwiftSyntaxBuilder.Format
    private var executableName = "codegen"
    private var pluginName = "CodegenPlugin"

    public func run() throws {
        guard fileManager.directoryExists(atPath: directory.path) else {
            throw MessageError("no directory: \(directory.relativePath)")
        }

        let manifestoFile = directory.appendingPathComponent("Package.swift")
        guard fileManager.fileExists(atPath: manifestoFile.path) else {
            throw MessageError("no manifesto file: \(manifestoFile.relativePath)")
        }

        var manifesto = try SyntaxParser.parse(manifestoFile)
        manifesto = try modifyPackageCall(manifesto: manifesto) { (packageCall) in
            return try modifyTargetsArray(packageCall: packageCall) { (targets) in
                return processTargetArray(targets: targets)
            }
        }
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
        print(elements.description)
        return targets.withElements(elements)
    }

    private func addExecutableTargetIfNone(elements: ArrayElementListSyntax) -> ArrayElementListSyntax {
        if elements.contains(where: { targetName($0) == executableName }) {
            return elements
        }

        var elements = elements

        let targetExpr = FunctionCallExpr(
            calledExpression: MemberAccessExpr(
                dot: .prefixPeriod, name: TokenSyntax.identifier("executableTarget")
            ),
            leftParen: .leftParen.withTrailingTrivia(.newlines(1)),
            argumentList: TupleExprElementList([
                TupleExprElement(
                    label: .identifier("name"),
                    colon: .colon,
                    expression: StringLiteralExpr(
                        openQuote: .stringQuote,
                        segments: StringLiteralSegments([
                            StringSegment(content: executableName)
                        ]),
                        closeQuote: .stringQuote
                    ),
                    trailingComma: .comma.withTrailingTrivia(.newlines(1))
                ),
                TupleExprElement(
                    label: .identifier("dependencies"),
                    colon: .colon,
                    expression: ArrayExpr(
                        elements: ArrayElementList([
                            ArrayElement(expression: IdentifierExpr("aaa"))

                        ]),
                        rightSquare: .rightSquareBracket.withTrailingTrivia(.newlines(1))
                    )
                )
            ]),
            rightParen: .rightParen
        )

        let newElement = ArrayElementSyntax(
            ArrayElement(expression: targetExpr, trailingComma: .comma)
                .buildSyntax(format: format)
        )!

        elements = elements.inserting(newElement, at: 0)

        return elements
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
