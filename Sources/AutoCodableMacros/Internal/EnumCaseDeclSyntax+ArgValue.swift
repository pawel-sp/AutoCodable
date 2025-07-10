import SwiftSyntax

extension EnumCaseDeclSyntax {
    func hasAttribute(containingString string: String) -> Bool {
        attributes
            .compactMap({ $0.as(AttributeSyntax.self) })
            .contains(where: { $0.attributeName.description.contains(string) })
    }

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
