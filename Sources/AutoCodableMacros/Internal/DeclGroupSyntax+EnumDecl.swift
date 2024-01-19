import SwiftSyntax

extension DeclGroupSyntax {
    func enumDecl(named name: String? = nil, ofType type: String) -> EnumDeclSyntax? {
        memberBlock.members
            .compactMap { $0.decl.as(EnumDeclSyntax.self) }
            .first(where: { decl in
                name.map { $0 == decl.name.text } ?? true &&
                decl.inheritanceClause?.inheritedTypes.contains(where: {
                    $0.type.as(IdentifierTypeSyntax.self)?.name.text == type
                }) == true
            })
    }
}
