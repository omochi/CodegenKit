# CodegenKit

Swift code generation framework.

## Usage

### Step1. Write code with placeholder

`@codegen(name)` and `@end` are placeholder marker.
Lines between them are edited by tool.

```swift
// TSDecl.swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    // @end
}
```

### Step2. Write yor renderer.

Write your renderer that conforms to `CodegenKit.Renderer`.
It will get source as `CodeTemplate`.
You can edit placeholder via subscript.

```swift
// TSDeclRenderer.swift
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

## Step3. Build your generator executable

Register your renderers to `CodegenKit.CodegenRunner` and invoke `run` method.
`CodegenRunner` scan applied directories recursively.

```swift
// main.swift
import Foundation
import CodegenKit

let runner = CodegenRunner(renderers: [
    TSDeclRenderer()
])
try runner.run(directories: [URL(fileURLWithPath: ".")])
```

```swift
let package = Package(
    ...
    targets: [
        ...
        .executableTarget(
            name: "codegen",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        )
        ...
    ],
    ...
)
```

## Step4. Run generator

```
$ swift run codegen
```

You will get generated code.

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

CodegenKit automatically format generated code by [swift-format](https://github.com/apple/swift-format).
So you don't have to worry about precise textual control like indenting when write renderer.

## Step5. (optional) Build package plugin

If you write [command plugin](https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md),
you can invoke codegen from package plugin.

```
$ swift package codegen
```

See examples to know how do this.

## Examples

- [TypeScriptAST](https://github.com/omochi/TypeScriptAST)
- [SwiftTypeReader](https://github.com/omochi/SwiftTypeReader)

# CodeTemplate

Small library for support **in place** code generation.
You can use this module independently from CodegenKit. 

## Usage

Write code as template with markers.

```swift
// Visitor.swift
class Visitor {
    ...

    // @codegen(visitImpl)
    func visitImpl(call: CallExpr) { ... }
    func visitImpl(ident: IdentExpr) { ... }
    // @end
}
```

Load code as template, edit, save.

```swift
let file = URL(fileURLWithPath: "Visitor.swift")
var template = try Template(file: file)
template["visitImpl"] = generateVisitImpl()
try template.description.write(to: file, atomically: true, encoding: .utf8)
```

## Detail

CodeTemplate just split source file by lines.
It doesn't see any syntax like comments, so it's target language agnostic.

