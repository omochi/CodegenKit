import SwiftSyntax
import CodegenKit

extension AbsolutePosition {
    func samePosition(in utf8: String.UTF8View) -> String.UTF8View.Index {
        return utf8.index(utf8.startIndex, offsetBy: utf8Offset)
    }

    func samePosition(in string: String) throws -> String.Index {
        let utf8Index = self.samePosition(in: string.utf8)
        guard let index = utf8Index.samePosition(in: string) else {
            throw MessageError("invalid position: \(self)")
        }
        return index
    }
}
