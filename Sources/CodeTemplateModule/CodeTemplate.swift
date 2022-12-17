import Foundation

public struct CodeTemplate: CustomStringConvertible {
    enum Fragment: Hashable {
        case text(String)
        case placeholder(name: String, content: String)

        var text: String? {
            switch self {
            case .text(let text): return text
            default: return nil
            }
        }

        var placeholder: (name: String, content: String)? {
            switch self {
            case .placeholder(name: let name, content: let content):
                return (name: name, content: content)
            default: return nil
            }
        }
    }

    public init(file: URL) throws {
        let string = try String(contentsOf: file)
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
            case .placeholder(name: let name, _):
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
            fragments[index] = .placeholder(name: name, content: newValue ?? "")
        }
    }

    public var description: String {
        var result = ""

        for fragment in fragments {
            switch fragment {
            case .text(let text): result += text
            case .placeholder(_, content: let text):
                result += text.ensuringNewline()
            }
        }

        return result
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
