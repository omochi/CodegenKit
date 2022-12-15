extension String {
    func splitLines() -> [String] {
        return LineSplitter(string: self).split()
    }
}

final class LineSplitter {
    init(string: String) {
        self.string = string
        self.index = string.startIndex
    }

    let string: String
    var index: String.Index

    func split() -> [String] {
        var lines: [String] = []

        while let line = readLine() {
            lines.append(line)
        }

        return lines
    }

    func readLine() -> String? {
        guard index < string.endIndex else { return nil }

        var line = ""

        while let c0 = readChar() {
            line.append(c0)

            switch c0 {
            case .lf:
                // ...<LF>
                return line
            case .cr:
                // ...<CR>
                return line
            case .crlf:
                // ...<CR><LF>
                return line
            default:
                break
            }
        }

        return line
    }

    private func peekChar() -> Character? {
        guard index < string.endIndex else { return nil }
        return string[index]
    }

    private func readChar() -> Character? {
        guard index < string.endIndex else { return nil }
        defer { advance() }
        return string[index]
    }

    private func advance() {
        index = string.index(after: index)
    }
}
