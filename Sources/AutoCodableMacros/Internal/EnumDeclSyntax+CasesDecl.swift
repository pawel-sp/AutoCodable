import SwiftSyntax

extension EnumDeclSyntax {
    func casesDecl() -> NamedDeclArray<EnumCaseDeclSyntax> {
        memberBlock.members
            .compactMap {
                if let enumCaseDecl = $0.decl.as(EnumCaseDeclSyntax.self), let name = enumCaseDecl.name {
                    (name, enumCaseDecl)
                } else {
                    nil
                }
            }
    }
}
