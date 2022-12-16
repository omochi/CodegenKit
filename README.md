# CodeTemplate

Small library for support **in place** code generation.

# Usage

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

# Example

- [TypeScriptAST](https://github.com/omochi/TypeScriptAST)
