# CodegenKit: a Swift code generation framework

CodegenKit helps you add lightweight code generation to Swift projects. It lets
you keep generated code directly in your Swift source files, while still making
the generated regions easy to update.

## Swift Code As The Template

Placeholders are marked directly in Swift source code:

```swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    // @end
}
```

Generated code is written between the `// @codegen(...)` and `// @end` markers.
CodegenKit does not require separate template files; your Swift source files are
the templates.

## Write Renderers In Swift

A renderer decides which files it handles and writes generated code into named
placeholders.

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
        let lines: [String] = nodes.map { node in
            """
public var as\(node.stem.pascal): \(node.typeName)? { self as? \(node.typeName) }
"""
        }
        return lines.joined(separator: "\n")
    }
}
```

Source files are passed to renderers as `CodeTemplate` values. You can read and
replace each placeholder through the template subscript.

## Indentation

CodegenKit uses the indentation of the `// @codegen(...)` marker as the base
indentation for generated code.

For example, this marker is indented by four spaces:

```swift
extension TSDecl {
    // @codegen(as)
    // @end
}
```

Every non-empty line assigned to `template["as"]` is written with those four
spaces added.

Renderers should generate code from the left edge, without the marker's base
indentation:

```swift
template["as"] = """
public var asClass: TSClassDecl? { self as? TSClassDecl }
public var asField: TSFieldDecl? { self as? TSFieldDecl }
"""
```

Keep relative indentation inside generated code. CodegenKit adds the marker's
base indentation to each non-empty line, but it does not infer or rewrite the
internal indentation of the generated code.

## Run Code Generation

After writing renderers, run code generation with:

```sh
swift package codegen
```

The source file is updated in place:

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

For setup details, see [Setup instructions](Docs/init.md).

## Documents

- [Setup instructions](Docs/init.md)
- [CodeTemplateModule sublibrary](Docs/CodeTemplateModule.md)
