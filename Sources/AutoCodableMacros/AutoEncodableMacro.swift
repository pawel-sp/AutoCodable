import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoEncodableMacro: MemberMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case onlyApplicableToExtension
        case missingCodingKeys

        public var description: String {
            switch self {
            case .onlyApplicableToExtension:
                "@AutoEncodable can be applied only to extensions."
            case .missingCodingKeys:
                "@AutoEncodable requires CodingKey enum provided when keyed or single value for enum container used."
            }
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(ExtensionDeclSyntax.self) else {
            throw Error.onlyApplicableToExtension
        }
        let arguments = node.args()

        let bodySyntax: CodeBlockSyntax
        switch arguments["container"] {
        case .member("keyed"), .none:
            bodySyntax = try keyedContainerBodySyntax(declaration: declaration)
        case let .function("singleValue", args):
            bodySyntax = try singleValueContainerBodySyntax(label: args[0])
        case .member("singleValueForEnum"):
            bodySyntax = try singleValueContainerForEnumBodySyntax(declaration: declaration)
        case .some:
            bodySyntax = CodeBlockSyntax(statements: .init([]))
        }

        let modifiers: DeclModifierListSyntax
        switch arguments["accessControl"] {
        case .member("public"):
            modifiers = [DeclModifierSyntax(name: TokenSyntax.keyword(.public))]
        default:
            modifiers = []
        }

        let funcDecl = FunctionDeclSyntax(
            modifiers: modifiers,
            name: TokenSyntax(stringLiteral: "encode"),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax(
                        arrayLiteral: FunctionParameterSyntax(
                            stringLiteral: "to encoder: Encoder"
                        )
                    )
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(throwsSpecifier: TokenSyntax.keyword(.throws))
            ),
            body: bodySyntax
        )

        return [.init(funcDecl)]
    }

    // MARK: Keyed Container

    private static func keyedContainerBodySyntax(declaration: some DeclGroupSyntax) throws -> CodeBlockSyntax {
        guard let mainEnumDecl = declaration.enumDecl(ofType: "CodingKey") else {
            throw Error.missingCodingKeys
        }
        let mainEnumName = mainEnumDecl.name.text
        let mainEnumCasesDecl = mainEnumDecl.casesDecl()
        let nestedEnumsDecl = mainEnumDecl.nestedEnumsDecl(named: mainEnumCasesDecl.map(\.name))

        return try CodeBlockSyntax {
            try VariableDeclSyntax(
                "var container = encoder.container(keyedBy: \(raw: mainEnumName).self)"
            )
            for nestedEnumDecl in nestedEnumsDecl {
                try VariableDeclSyntax(
                    """
                    var \(raw: nestedEnumDecl.name)Container = container.nestedContainer(
                        keyedBy: \(raw: mainEnumName).\(raw: nestedEnumDecl.decl.name.text).self,
                        forKey: .\(raw: nestedEnumDecl.name)
                    )
                    """
                )
            }
            for caseMember in mainEnumCasesDecl {
                let conditional = caseMember.decl.hasAttribute(containingString: "Conditional")
                if let encodedValue = caseMember.decl.argValue(forAttributeName: "EncodedValue") {
                    keyedContainerEncodingArgumentSyntax(
                        label: caseMember.name,
                        encodeType: encodedValue.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
                        conditional: conditional
                    )
                } else if let nestedEnumDecl = nestedEnumsDecl.first(where: { $0.name == caseMember.name })?.decl {
                    for nestedCaseMember in nestedEnumDecl.casesDecl() {
                        let conditional = nestedCaseMember.decl.hasAttribute(containingString: "Conditional")
                        if let encodedValue = nestedCaseMember.decl.argValue(forAttributeName: "EncodedValue") {
                            keyedContainerEncodingArgumentSyntax(
                                label: nestedCaseMember.name,
                                containerName: "\(caseMember.name)Container",
                                encodeType: encodedValue.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
                                conditional: conditional
                            )
                        } else {
                            keyedContainerEncodingArgumentSyntax(
                                label: nestedCaseMember.name,
                                containerName: "\(caseMember.name)Container",
                                conditional: conditional
                            )
                        }
                    }
                } else {
                    keyedContainerEncodingArgumentSyntax(
                        label: caseMember.name,
                        conditional: conditional
                    )
                }
            }
        }
    }

    private static func keyedContainerEncodingArgumentSyntax(
        label: String,
        containerName: String = "container",
        encodeType: String? = nil,
        conditional: Bool
    ) -> FunctionCallExprSyntax {
        let condition = conditional ? "IfPresent" : .init()
        return .init(callee: ExprSyntax("try \(raw: containerName).encode\(raw: condition)")) {
            LabeledExprListSyntax {
                LabeledExprSyntax(
                    expression: ExprSyntax(stringLiteral: encodeType.map { "\($0)(from: \(label))" } ?? label)
                )
                LabeledExprSyntax(
                    label: "forKey",
                    expression: ExprSyntax(stringLiteral: ".\(label)")
                )
            }
        }
    }

    // MARK: Single Value Container

    private static func singleValueContainerBodySyntax(label: String) throws -> CodeBlockSyntax {
        try CodeBlockSyntax(
            statementsBuilder: {
                try VariableDeclSyntax("var container = encoder.singleValueContainer()")
                FunctionCallExprSyntax(callee: ExprSyntax("try container.encode")) {
                    LabeledExprSyntax(expression: ExprSyntax(stringLiteral: label))
                }
            }
        )
    }

    // MARK: Single Value Container for Enum

    private static func singleValueContainerForEnumBodySyntax(
        declaration: some DeclGroupSyntax
    ) throws -> CodeBlockSyntax {
        guard let mainEnumDecl = declaration.enumDecl(ofType: "CodingKey") else {
            throw Error.missingCodingKeys
        }
        let mainEnumName = mainEnumDecl.name.text
        let mainEnumCasesDecl = mainEnumDecl.casesDecl()
        return try CodeBlockSyntax(
            statementsBuilder: {
                try VariableDeclSyntax("var container = encoder.singleValueContainer()")
                SwitchExprSyntax(
                    subject: ExprSyntax("self"),
                    cases: SwitchCaseListSyntax {
                        for caseMember in mainEnumCasesDecl {
                            singleValueContainerCaseSyntax(
                                label: caseMember.name,
                                codingKeyName: "\(mainEnumName).\(caseMember.name).rawValue"
                            )
                        }
                    }
                )
            }
        )
    }

    private static func singleValueContainerCaseSyntax(label: String, codingKeyName: String) -> SwitchCaseSyntax {
        .init(
            label: .case(
                SwitchCaseLabelSyntax(
                    caseItems: .init {
                        SwitchCaseItemSyntax(
                            pattern: ExpressionPatternSyntax(
                                expression: ExprSyntax(stringLiteral: ".\(label)")
                            )
                        )
                    }
                )
            )
        ) {
            ExprSyntax("try container.encode(\(raw: codingKeyName))")
        }
    }
}
