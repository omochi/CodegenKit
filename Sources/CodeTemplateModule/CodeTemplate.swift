import Foundation

public struct CodeTemplate: CustomStringConvertible {
    enum Fragment: Hashable {
        case text(String)
        case placeholder(name: String, indentation: String, content: String)

        var text: String? {
            switch self {
            case .text(let text): return text
            default: return nil
            }
        }

        var placeholder: (name: String, content: String)? {
            switch self {
            case .placeholder(name: let name, _, content: let content):
                return (name: name, content: content)
            default: return nil
            }
        }

        var placeholderIndentation: String? {
            switch self {
            case .placeholder(_, indentation: let indentation, _):
                return indentation
            default:
                return nil
            }
        }
    }

    public init(file: URL) throws {
        let string = try String(contentsOf: file, encoding: .utf8)
        self.init(string: string)
    }

    public init(string: String) {
        let parser = Parser(string: string)
        self = parser.parse()
    }

    internal init(fragments: [Fragment]) {
        self.fragments = fragments
        self.buildIndexMap()
    }

    var fragments: [Fragment] = []
    private var indexMap: [String: Int] = [:]

    private mutating func buildIndexMap() {
        indexMap.removeAll()

        for (index, fragment) in fragments.enumerated() {
            switch fragment {
            case .text: break
            case .placeholder(name: let name, _, _):
                indexMap[name] = index
            }
        }
    }

    public var names: [String] {
        fragments.compactMap { $0.placeholder?.name }
    }

    public subscript(name: String) -> String? {
        get {
            guard let index = indexMap[name],
                  let placeholder = fragments[index].placeholder else { return nil }
            return placeholder.content
        }
        set {
            guard let index = indexMap[name] else { return }
            let indentation = fragments[index].placeholderIndentation ?? ""
            fragments[index] = .placeholder(
                name: name,
                indentation: indentation,
                content: newValue ?? ""
            )
        }
    }

    public var description: String {
        var result = ""

        for fragment in fragments {
            switch fragment {
            case .text(let text): result += text
            case .placeholder(_, indentation: let indentation, content: let text):
                result += text.ensuringNewline().indentingNonEmptyLines(with: indentation)
            }
        }

        return result
    }
}

extension String {
    func indentingNonEmptyLines(with indentation: String) -> String {
        guard !indentation.isEmpty else { return self }
        return splitLines().map { line in
            line.contains { $0 != .lf && $0 != .cr && $0 != .crlf }
                ? indentation + line
                : line
        }.joined()
    }

    func removingIndentationFromNonEmptyLines(_ indentation: String) -> String {
        guard !indentation.isEmpty else { return self }
        return splitLines().map { line in
            guard line.contains(where: { $0 != .lf && $0 != .cr && $0 != .crlf }) else {
                return line
            }
            guard line.hasPrefix(indentation) else {
                return line
            }
            return String(line.dropFirst(indentation.count))
        }.joined()
    }
}

extension String {
    func ensuringNewline() -> String {
        if let last = self.last {
            switch last {
            case .lf, .cr, .crlf: return self
            default: break
            }
        }

        return self + "\n"
    }
}
