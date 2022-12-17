import Foundation

public protocol Renderer {
    func isTarget(file: URL) -> Bool
    func render(template: inout Template, on runner: CodegenRunner) throws
}
