public struct CodegenFormatConfiguration: Sendable {
    public init(indentationSpaces: Int = 4) {
        self.indentationSpaces = indentationSpaces
    }

    public var indentationSpaces: Int
}
