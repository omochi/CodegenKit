# CodegenKit: Swift code generation framework

This is a framework for introducing code generation on your Swift project.
You can do meta-programming like below.

## Code becomes template as it is

Placeholders are defined by markers in Swift code as follows.

```swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    // @end
}
```

Generated codes are inserted in area between markers.

Thus, CodegenKit doesn't use any specific template files.
Instead, Swift source codes are used as a template.

## Write code renderer in Swift

Write code renderer as follows.

```swift
import Foundation
import CodegenKit

struct Node {
    var stem: String
    var typeName: String
}

struct TSDeclRenderer: Renderer {
    var nodes: [Node] = [...]

    func isTarget(file: URL) -> Bool {
        file.lastPathComponent == "TSDecl.swift"
    }

    func render(template: inout CodeTemplate, file: URL, on runner: CodegenRunner) throws {
        template["as"] = asCasts()
    }

    func asCasts() -> String {
        let lines: [String] = nodes.map { (node) in
            """
public var as\(node.stem.pascal): \(node.typeName)? { self as? \(node.typeName) }
"""
        }
        return lines.joined(separator: "\n")
    }
}
```

Your source code are passed as `CodeTemplate` object.
You can edit contents of placeholder via subscript.

## Do code generation

After writing renderers, generate codes.
Perform code generation with following command.

```
$ swift package codegen
```

Previous code will be edited as follows.

```swift
// TSDecl.swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    public var asClass: TSClassDecl? { self as? TSClassDecl }
    public var asField: TSFieldDecl? { self as? TSFieldDecl }
    public var asFunction: TSFunctionDecl? { self as? TSFunctionDecl }
    public var asImport: TSImportDecl? { self as? TSImportDecl }
    public var asInterface: TSInterfaceDecl? { self as? TSInterfaceDecl }
    public var asMethod: TSMethodDecl? { self as? TSMethodDecl }
    public var asNamespace: TSNamespaceDecl? { self as? TSNamespaceDecl }
    public var asSourceFile: TSSourceFile? { self as? TSSourceFile }
    public var asType: TSTypeDecl? { self as? TSTypeDecl }
    public var asVar: TSVarDecl? { self as? TSVarDecl }
    // @end
}
```

Let's start and enjoy code generation!
Please read [this document](Docs/init.md) for detailed setup instructions.

# Documents

- [Setup instructions](Docs/init.md)
- [CodeTemplateModule sublibrary](Docs/CodeTemplateModule.md)


