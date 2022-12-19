import Foundation

extension String {
    private static let randomChars: [Character] = [
        "abcdefghijklmnopqrstuvwxyz",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "0123456789"
    ].flatMap { $0 }

    static func random() -> String {
        return String((0..<8).map { (_) in
            Self.randomChars.randomElement()!
        })
    }
}

struct WorkspaceBuilder {
    init(namespace: String = "CodegenKitCLITests") {
        self.fileManager = FileManager.default
        self.base = URL(
            fileURLWithPath: fileManager.temporaryDirectory
                .appendingPathComponent(namespace)
                .appendingPathComponent(String.random()).path,
            isDirectory: true
        )
    }

    var fileManager: FileManager
    var base: URL

    func path(_ path: String) -> URL {
        return URL(fileURLWithPath: path, relativeTo: base)
    }

    func addDirectory(path: String) throws {
        let path = self.path(path)
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
    }

    func addFile(path: String, data: Data) throws {
        let path = self.path(path)
        try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: path, options: .atomic)
    }

    func addFile(path: String, string: String) throws {
        try addFile(path: path, data: string.data(using: .utf8)!)
    }
}
