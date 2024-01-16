import SwiftSyntax

extension EnumCaseDeclSyntax {
    var name: String? {
        elements.first.map(\.name.text)
    }
}
