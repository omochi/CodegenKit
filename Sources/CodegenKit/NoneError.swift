public struct NoneError: Error & CustomStringConvertible {
    public init(name: String) {
        self.name = name
    }

    public var name: String

    public var description: String {
        "\(name) is none"
    }
}
