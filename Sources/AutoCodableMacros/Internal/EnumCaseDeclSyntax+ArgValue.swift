import SwiftSyntax

extension EnumCaseDeclSyntax {
    func argValue(forAttributeName attributeName: String) -> MemberAccessExprSyntax? {
        guard
            let attribute = attributes
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: { $0.attributeName.description == attributeName }),
            let value = attribute
                .arguments?
                .as(LabeledExprListSyntax.self)?
                .first?
                .expression
                .as(MemberAccessExprSyntax.self)
        else {
            return nil
        }
        return value
    }
}
