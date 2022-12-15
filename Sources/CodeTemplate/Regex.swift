import Foundation

/*
 MacOS Ventura is too early.
 */

final class Regex {
    public struct MatchResult {
        public struct Entry {
            public let sourceString: String
            public let nsResult: NSTextCheckingResult
            public let index: Int

            public var range: Range<String.Index>? {
                let nsRange = nsResult.range(at: index)
                guard nsRange.location != NSNotFound else {
                    return nil
                }
                return Range.init(nsRange, in: sourceString)
            }

            public var string: String? {
                guard let range = self.range else { return nil }
                return String(sourceString[range])
            }
        }

        public init(sourceString: String,
                    nsResult: NSTextCheckingResult)
        {
            self.sourceString = sourceString
            self.nsResult = nsResult
        }

        public let sourceString: String
        public let nsResult: NSTextCheckingResult

        public var entries: [Entry] {
            return (0..<count)
                .map { index in
                    return Entry(sourceString: sourceString,
                                 nsResult: nsResult,
                                 index: index)
            }
        }

        public var count: Int {
            return nsResult.numberOfRanges
        }

        public subscript(index: Int) -> String? {
            guard 0 <= index && index < count else { return nil }

            return entries[index].string
        }
    }

    public init(pattern: String, options: NSRegularExpression.Options = []) throws {
        self.nsRegex = try NSRegularExpression(pattern: pattern, options: options)
    }

    public func match(string: String,
                      options: NSRegularExpression.MatchingOptions = [],
                      range: Range<String.Index>? = nil) -> MatchResult?
    {
        let range = range ?? (string.startIndex..<string.endIndex)
        guard let nsResult = nsRegex.firstMatch(in: string,
                                                options: options,
                                                range: NSRange.init(range, in: string)) else
        {
            return nil
        }

        return MatchResult(sourceString: string,
                           nsResult: nsResult)
    }

    public func matches(string: String,
                        options: NSRegularExpression.MatchingOptions = [],
                        range: Range<String.Index>? = nil) -> [MatchResult]
    {
        let range = range ?? (string.startIndex..<string.endIndex)
        let nsResults = nsRegex.matches(in: string,
                                        options: options,
                                        range: NSRange.init(range, in: string))
        return nsResults
            .map { MatchResult(sourceString: string,
                               nsResult: $0) }
    }

    private let nsRegex: NSRegularExpression
}
