# CodeTemplate

`CodeTemplateModule` is a small library for in-place code generation. It can be
used independently from CodegenKit.

## Usage

Mark generated regions directly in a source file:

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

Load the file as a template, replace a placeholder, and write the file back:

```swift
let file = URL(fileURLWithPath: "Visitor.swift")
var template = try Template(file: file)
template["visitImpl"] = generateVisitImpl()
try template.description.write(to: file, atomically: true, encoding: .utf8)
```

## Details

`CodeTemplate` splits the source file by lines and looks for `@codegen` and
`@end` markers. It does not parse the surrounding language, comments, or syntax,
so the module is language-agnostic.

When a placeholder is parsed, `CodeTemplate` records the indentation of the
`@codegen` marker line. Placeholder contents are exposed without that base
indentation. When the template is rendered back to text, the marker indentation
is added to each non-empty generated line.
