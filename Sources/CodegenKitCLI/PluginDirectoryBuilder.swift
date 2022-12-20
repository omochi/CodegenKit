import Foundation

struct PluginDirectoryBuilder {
    var fileManager: FileManager
    var dir: URL
    var executableName: String
    var pluginName: String

    func build() throws {
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        try createFile(path: "\(pluginName).swift", source: """
import Foundation
import PackagePlugin

@main
struct \(pluginName): CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "\(executableName)")

        let sourcesDir = context.package.directory.appending(subpath: "Sources")

        let process = EasyProcess(
            path: URL(fileURLWithPath: tool.path.string),
            args: [sourcesDir.string]
        )
        try process.run()
    }
}
"""
        )
        try createFile(path: "EasyProcess.swift", source: """
import Foundation

struct EasyProcess {
    init(
        path: URL,
        args: [String],
        outSink: ((Data) -> Void)? = nil,
        errorSink: ((Data) -> Void)? = nil
    ) {
        self.path = path
        self.args = args
        self.outSink = outSink ?? Self.defaultOutSink
        self.errorSink = errorSink ?? Self.defaultErrorSink
    }

    var path: URL
    var args: [String]
    var outSink: (Data) -> Void
    var errorSink: (Data) -> Void

    static func makeFileHandleSink(fileHandle: FileHandle) -> (Data) -> Void {
        return { (data) in
            try? fileHandle.write(contentsOf: data)
        }
    }

    static var defaultOutSink: (Data) -> Void {
        makeFileHandleSink(fileHandle: .standardOutput)
    }

    static var defaultErrorSink: (Data) -> Void {
        makeFileHandleSink(fileHandle: .standardError)
    }

    @discardableResult
    func run() throws -> Int32 {
        let queue = DispatchQueue(label: "EasyProcess.run")

        let p = Process()
        p.executableURL = path
        p.arguments = args

        let outPipe = Pipe()
        p.standardOutput = outPipe

        outPipe.fileHandleForReading.readabilityHandler = { (h) in
            queue.sync {
                let data = h.availableData
                if !data.isEmpty {
                    outSink(data)
                }
            }
        }

        let errPipe = Pipe()
        p.standardError = errPipe

        errPipe.fileHandleForReading.readabilityHandler = { (h) in
            queue.sync {
                let data = h.availableData
                if !data.isEmpty {
                    errorSink(data)
                }
            }
        }

        try p.run()

        p.waitUntilExit()

        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil

        try queue.sync {
            if let data = try outPipe.fileHandleForReading.readToEnd(),
               !data.isEmpty
            {
                outSink(data)
            }
            if let data = try errPipe.fileHandleForReading.readToEnd(),
               !data.isEmpty
            {
                errorSink(data)
            }
        }

        return p.terminationStatus
    }
}
"""
        )
    }

    private func createFile(path: String, source: String) throws {
        let file = dir.appendingPathComponent(path)
        try source.write(to: file, atomically: true, encoding: .utf8)
    }
}
