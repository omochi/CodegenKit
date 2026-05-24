final class Parser {
    init(string: String) {
        self.lines = string.splitLines()
        self.index = 0
    }

    let lines: [String]
    var index: Int

    func parse() -> CodeTemplate {
        var fragments: [CodeTemplate.Fragment] = []
        while true {
            guard let text = readTextFragment() else {
                break
            }
            fragments.append(.text(text.text))

            guard let placeholder = text.nextPlaceholder else {
                break
            }
            guard let placeholderContent = readPlaceholderFragment() else {
                break
            }
            fragments.append(
                .placeholder(
                    name: placeholder.name,
                    indentation: placeholder.indentation,
                    content: placeholderContent.removingIndentationFromNonEmptyLines(
                        placeholder.indentation
                    )
                )
            )
        }
        return CodeTemplate(fragments: fragments)
    }

    struct TextFragment {
        var text: String
        var nextPlaceholder: (name: String, indentation: String)?
    }

    private func readTextFragment() -> TextFragment? {
        guard index < lines.count else { return nil }

        var text = ""
        var placeholder: (name: String, indentation: String)? = nil
        while index < lines.count {
            let line = lines[index]
            text += line
            index += 1
            if let mr = beginRegex.match(string: line) {
                placeholder = (
                    name: mr[1] ?? "",
                    indentation: line.indentationBeforeMatch(mr)
                )
                break
            }
        }

        return TextFragment(
            text: text,
            nextPlaceholder: placeholder
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

private extension String {
    func indentationBeforeMatch(_ match: Regex.MatchResult) -> String {
        guard let marker = match.entries.first?.range?.lowerBound else {
            return ""
        }

        return String(self[..<marker].prefix { $0 == " " || $0 == "\t" })
    }
}
