public struct SwiftWriter {
    public init() {}

    public var keywords = [
        "as",
        "await",
        "case",
        "catch",
        "class",
        "else",
        "default",
        "if",
        "import",
        "return",
        "subscript",
        "switch",
        "throw",
        "try",
        "var"
    ]

    public func ident(_ string: String) -> String {
        if keywords.contains(string) {
            return escapeIdent(string)
        } else {
            return string
        }
    }

    public func escapeIdent(_ string: String) -> String {
        return "`" + string + "`"
    }
}
