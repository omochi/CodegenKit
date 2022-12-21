# Setup instructions

## Step 1. Install CodegenKit into your project

Add `CodegenKit` as dependency of your project.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.2.1")
    ]
    ...
)
```

## Step 2. Setup your project

Perform command below.

```
$ swift package codegen-kit init
```

This is all that is needed to complete the required setup.

Instead of command, you can do it manually.
In that case, see instructions described later in this document.

## Step 3. Write placeholder into code

Define placeholders with `@codegen` and `@end` as follows.

```swift
// TSDecl.swift
protocol TSDecl {}

extension TSDecl {
    // @codegen(as)
    // @end
}
```

Attach name of placeholder at `@codegen`.

## Step 4. Implement code renderer

The init command created executable target named `codegen`.
Add your renderer code into this.

Implement renderers to conform `CodegenKit.Renderer` as follows.

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

Specify target source code for this renderer with `isTarget` method.

Write rendering logics into `render` method.
Your source code are passwd as `CodeTemplate` object,
you can edit content of placeholders via subscript.

CodegenKit automatically format generated code by [swift-format](https://github.com/apple/swift-format).
So you don't have to worry about precise textual control like indenting when write renderer.

## Step 5. Register your renderers to the runner.

The init command created `main.swift` in `codegen` target.
The codegen runner is defined in here.

Edit this source to register your renderer to the runner.

```swift
import CodegenKit

let runner = CodegenRunner(renderers: [
    TSDeclRenderer()
])
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try runner.run(directories: [dir])
```

## Step 6. Perform code generation

The init command created `codegen` command plugin.
So you can perform code generation as below.

```
$ swift package codegen
```

# More advanced code generation

CodegenKit initially creates `codegen` executable and plugin by the init command,
but has no requirements for these specifications after that.

So, you can modify these targets source and build more complex code generations.

# Setup manually

To setup it manually without using the init command, do the following steps instead.

## Step 1. Create codegen executable

Create `codegen` executable target.

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

You can use any target name other than `codegen`.

Write main file that build `CodegenKit.CodegenRunner` and run it.

```swift
import CodegenKit

let runner = CodegenRunner(renderers: [
    TSDeclRenderer()
])
let dir = URL(fileURLWithPath: CommandLine.arguments[1])
try runner.run(directories: [dir])
```

There are no specification about anything including command line arguments.
Above example build as run on current working directory.

After that, you can generate code as below.

```
$ swift run codegen .
```

## Step 2 (Optional). Create command plugin

You can create [command plugin](https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md) 
that perform previous `codegen` executable.

After that, you can generate code as below.

```
$ swift package codegen
```


