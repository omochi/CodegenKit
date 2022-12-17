import Foundation

extension FileManager {
    public func directoryExists(atPath path: String) -> Bool {
        var isDirectory = ObjCBool(false)
        guard fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        return isDirectory
    }
}
