import Foundation

public protocol Renderer {
    func isTarget(file: URL) -> Bool
    func render(template: inout CodeTemplate, file: URL, on runner: CodegenRunner) throws
}
