final class Parser {
    init(string: String) {
        self.lines = string.splitLines()
        self.index = 0
    }

    let lines: [String]
    var index: Int

    func parse() -> Template {
        var fragments: [Template.Fragment] = []
        while true {
            guard let text = readTextFragment() else {
                break
            }
            fragments.append(.text(text.text))

            guard let placeholderName = text.nextPlaceholderName else {
                break
            }
            guard let placeholderContent = readPlaceholderFragment() else {
                break
            }
            fragments.append(
                .placeholder(
                    name: placeholderName,
                    content: placeholderContent
                )
            )
        }
        return Template(fragments: fragments)
    }

    struct TextFragment {
        var text: String
        var nextPlaceholderName: String?
    }

    private func readTextFragment() -> TextFragment? {
        guard index < lines.count else { return nil }

        var text = ""
        var placeholderName: String? = nil
        while index < lines.count {
            let line = lines[index]
            text += line
            index += 1
            if let mr = beginRegex.match(string: line) {
                placeholderName = mr[1]
                break
            }
        }

        return TextFragment(
            text: text,
            nextPlaceholderName: placeholderName
        )
    }

    private func readPlaceholderFragment() -> String? {
        guard index < lines.count else { return nil }

        var text = ""
        while index < lines.count {
            let line = lines[index]
            if let _ = endRegex.match(string: line) {
                break
            } else {
                text += line
                index += 1
            }
        }
        return text
    }

    let beginRegex = try! Regex(
        pattern: #"@codegen\(([\w\-]*)\)"#
    )
    let endRegex = try! Regex(
        pattern: #"@end"#
    )
}
