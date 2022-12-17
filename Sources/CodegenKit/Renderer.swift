import Foundation

public protocol Renderer {
    func isTarget(file: URL) -> Bool
    func render(template: inout CodeTemplate, on runner: CodegenRunner) throws
}
