import SwiftSyntax

extension AttributeSyntax {
    enum Arg {
        case member(String)
        case function(String?, args: [String])
    }

    func args() -> [String: Arg] {
        let args: LabeledExprListSyntax = {
            if case let .argumentList(args) = arguments { args }
            else { [] }
        }()
        return args.reduce(into: [String: Arg]()) {
            guard let key = $1.label?.text else {
                return
            }
            if let member = $1.expression.as(MemberAccessExprSyntax.self) {
                $0[key] = .member(member.declName.baseName.text)
            } else if let function = $1.expression.as(FunctionCallExprSyntax.self) {
                $0[key] = .function(
                    function.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text,
                    args: function.arguments
                        .compactMap { $0.expression.as(StringLiteralExprSyntax.self) }
                        .flatMap { $0.segments }
                        .compactMap { $0.as(StringSegmentSyntax.self) }
                        .map(\.content.text)
                )
            }
        }
    }
}
