import Foundation
import SwiftFormat
import SwiftFormatConfiguration

public final class CodegenRunner {
    public init(
        renderers: [any Renderer],
        formatConfiguration: SwiftFormatConfiguration.Configuration? = nil
    ) {
        self.renderers = renderers
        self.formatConfiguration = formatConfiguration ?? Self.defaultFormatCondiguration()
        self.fileManager = .default
    }

    public var renderers: [any Renderer]
    public var formatConfiguration: SwiftFormatConfiguration.Configuration
    private let fileManager: FileManager

    public static func defaultFormatCondiguration() -> SwiftFormatConfiguration.Configuration {
        var c = SwiftFormatConfiguration.Configuration()
        c.lineLength = 10000
        c.indentation = .spaces(4)
        return c
    }

    public func run(directories: [URL]) throws {
        for directory in directories {
            try walk(directory: directory)
        }
    }

    private func walk(directory: URL) throws {
        for file in fileManager.enumerateRelative(path: directory, options: [.skipsHiddenFiles]) {
            if fileManager.directoryExists(atPath: file.path) { continue }

            if file.lastPathComponent.hasSuffix(".swift") {
                try render(file: file)
            }
        }
    }

    private func render(file: URL) throws {
        guard let renderer = self.renderers.first(where: {
            $0.isTarget(file: file)
        }) else { return }

        var template = try CodeTemplate(file: file)
        try renderer.render(template: &template, file: file, on: self)
        var source = template.description
        source = try self.format(source: source, file: file)
        try writeIfChanged(data: source.data(using: .utf8)!, file: file)
    }

    public func format(source: String, file: URL) throws -> String {
        let formatter = SwiftFormatter(configuration: formatConfiguration)
        var result = ""
        try formatter.format(source: source, assumingFileURL: file, to: &result)
        return result
    }

    public func writeIfChanged(data: Data, file: URL) throws {
        let original = try Data(contentsOf: file)
        if data == original { return }
        try data.write(to: file, options: .atomic)
        print("updated: \(file.relativePath)")
    }
}
