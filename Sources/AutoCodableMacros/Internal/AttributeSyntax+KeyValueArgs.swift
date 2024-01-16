import SwiftSyntax

extension AttributeSyntax {
    func keyValueArgs() -> [String: String] {
        let args: LabeledExprListSyntax = {
            if case let .argumentList(args) = arguments { args }
            else { [] }
        }()
        return args.reduce(into: [String: String]()) {
            let key = $1.label?.text
            let value = $1.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
            if let key {
                $0[key] = value
            }
        }
    }
}
