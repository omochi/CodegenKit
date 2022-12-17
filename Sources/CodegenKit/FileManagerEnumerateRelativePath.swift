import Foundation

extension FileManager {
    public func enumerateRelative(
        path: URL,
        options: Set<EnumerateRelativePath.Option>
    ) -> EnumerateRelativePath {
        return EnumerateRelativePath(fileManager: self, base: path, options: options)
    }
}

public struct EnumerateRelativePath: Sequence {
    public enum Option {
        case skipsHiddenFiles
    }

    public typealias Element = URL

    var fileManager: FileManager
    var base: URL
    var options: Set<Option>

    public struct Iterator: IteratorProtocol {
        var sequence: EnumerateRelativePath
        var enumerator: FileManager.DirectoryEnumerator?

        public func next() -> URL? {
            guard let enumerator else { return nil }

            while true {
                guard let path = enumerator.nextObject() as? String else { return nil }

                if sequence.options.contains(.skipsHiddenFiles), path.hasPrefix(".") {
                    continue
                }

                return URL(fileURLWithPath: path, relativeTo: sequence.base)
            }
        }
    }

    public func makeIterator() -> Iterator {
        return Iterator(
            sequence: self,
            enumerator: fileManager.enumerator(atPath: base.relativePath)
        )
    }
}
