import Foundation
import PackagePlugin

@main
struct CodegenKitPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "codegenkit")

        let process = EasyProcess(
            path: URL(fileURLWithPath: tool.path.string),
            args: arguments
        )
        try process.run()
    }
}
