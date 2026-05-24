# Setup Instructions

## Step 1. Add CodegenKit To Your Package

Add `CodegenKit` as a dependency of your project.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.2.2")
    ]
    ...
)
```

## Step 2. Initialize Your Project

Run the initialization command:

```sh
swift package codegen-kit init
```

This performs the required setup. If you prefer to configure the package
manually, see [Setup Manually](#setup-manually).

## Step 3. Add Placeholders To Source Files

Define placeholders with `// @codegen(...)` and `// @end` markers:

```swift
// TSDecl.swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    // @end
}
```

The name inside `@codegen(...)` identifies the placeholder.

## Step 4. Implement A Renderer

The init command creates an executable target named `codegen`. Add your renderer
code to that target.

Renderers conform to `CodegenKit.Renderer`:

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

Use `isTarget(file:)` to choose which source files the renderer handles. Put the
generation logic in `render(template:file:on:)`. The source file is provided as
a `CodeTemplate`, and placeholders can be read or replaced through the template
subscript.

Render generated code from the left edge. CodegenKit reads the indentation of
the `// @codegen(...)` marker and applies that base indentation when writing the
generated code back to the file. Relative indentation inside the generated code
is preserved.

## Step 5. Register Renderers With The Runner

The init command creates a `main.swift` file in the `codegen` target. Register
your renderers there:

```swift
import CodegenKit

let runner = CodegenRunner(renderers: [
    TSDeclRenderer()
])
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try runner.run(directories: [dir])
```

## Step 6. Run Code Generation

The init command also creates a SwiftPM command plugin, so you can run:

```sh
swift package codegen
```

## More Advanced Code Generation

The init command creates a `codegen` executable and command plugin as a starting
point. After initialization, CodegenKit does not require that exact structure.
You can change the executable, command-line interface, plugin, or renderer
registration to fit more complex workflows.

# Setup Manually

If you do not want to use the init command, configure the package with the
following steps.

## Step 1. Create A Codegen Executable

Create an executable target that depends on CodegenKit.

```swift
let package = Package(
    ...
    targets: [
        .executableTarget(
            name: "codegen",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        ),
    ...
)
```

The target does not have to be named `codegen`; use any name that fits your
project.

Add a main file that builds and runs a `CodegenRunner`:

```swift
import CodegenKit

let runner = CodegenRunner(renderers: [
    TSDeclRenderer()
])
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try runner.run(directories: [dir])
```

CodegenKit does not impose any command-line argument format. The example above
expects a directory path and runs generation in that directory.

You can then run code generation with:

```sh
swift run codegen .
```

## Step 2. Create A Command Plugin (Optional)

You can also create a SwiftPM
[command plugin](https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md)
that invokes the codegen executable.

With that plugin in place, you can run:

```sh
swift package codegen
```
