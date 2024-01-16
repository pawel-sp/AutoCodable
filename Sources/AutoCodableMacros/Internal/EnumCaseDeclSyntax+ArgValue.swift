import SwiftSyntax

extension EnumCaseDeclSyntax {
    func argValue(forAttributeName attributeName: String) -> ExprSyntax? {
        guard
            let attribute = attributes
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: { $0.attributeName.description == attributeName }),
            let value = attribute
                .arguments?
                .as(LabeledExprListSyntax.self)?
                .first?
                .expression
        else {
            return nil
        }
        return value
    }
}
