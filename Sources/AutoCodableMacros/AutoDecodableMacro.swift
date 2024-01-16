import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoDecodableMacro: MemberMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case onlyApplicableToExtension
        case missingCodingKeys

        public var description: String {
            switch self {
            case .onlyApplicableToExtension:
                "@AutoDecodable can be applied only to extensions."
            case .missingCodingKeys:
                "@AutoDecodable requires CodingKey enum provided when keyed or single value for enum container used."
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
        let labelValuePairs = node.keyValueArgs()

        let bodySyntax: CodeBlockSyntax
        switch labelValuePairs["container"] {
        case "keyed", .none:
            bodySyntax = try keyedContainerBodySyntax(declaration: declaration)
        case "singleValue":
            bodySyntax = try singleValueContainerBodySyntax()
        case "singleValueForEnum":
            bodySyntax = try singleValueContainerForEnumBodySyntax(declaration: declaration)
        case .some:
            bodySyntax = CodeBlockSyntax(statements: .init([]))
        }

        let modifiers: DeclModifierListSyntax
        switch labelValuePairs["accessControl"] {
        case "public":
            modifiers = [DeclModifierSyntax(name: TokenSyntax.keyword(.public))]
        default:
            modifiers = []
        }

        let initializerDecl = InitializerDeclSyntax(
            modifiers: modifiers,
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax(
                        arrayLiteral: FunctionParameterSyntax(
                            stringLiteral: "from decoder: Decoder"
                        )
                    )
                ),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(throwsSpecifier: TokenSyntax.keyword(.throws))
            ),
            body: bodySyntax
        )

        return [.init(initializerDecl)]
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
                "let container = try decoder.container(keyedBy: \(raw: mainEnumName).self)"
            )
            for nestedEnumDecl in nestedEnumsDecl {
                try VariableDeclSyntax(
                    """
                    let \(raw: nestedEnumDecl.name)Container = try container.nestedContainer(
                        keyedBy: \(raw: mainEnumName).\(raw: nestedEnumDecl.decl.name.text).self,
                        forKey: .\(raw: nestedEnumDecl.name)
                    )
                    """
                )
            }
            FunctionCallExprSyntax(
                calledExpression: ExprSyntax("try self.init"),
                leftParen: .leftParenToken(),
                arguments: keyedContainerInitArgumentsSyntax(
                    mainEnumCasesDecl: mainEnumCasesDecl,
                    nestedEnumsDecl: nestedEnumsDecl
                ),
                rightParen: .rightParenToken(leadingTrivia: .newline)
            )
        }
    }

    private static func keyedContainerInitArgumentsSyntax(
        mainEnumCasesDecl: NamedDeclArray<EnumCaseDeclSyntax>,
        nestedEnumsDecl: NamedDeclArray<EnumDeclSyntax>
    ) -> LabeledExprListSyntax {
        .init {
            for caseMember in mainEnumCasesDecl {
                if let decodedValue = caseMember.decl.argValue(forAttributeName: "DecodedValue") {
                    keyedContainerInitArgumentSyntax(label: caseMember.name, decodeType: decodedValue.description)
                } else if let nestedEnumDecl = nestedEnumsDecl.first(where: { $0.name == caseMember.name })?.decl {
                    for nestedCaseMember in nestedEnumDecl.casesDecl() {
                        if let decodedValue = nestedCaseMember.decl.argValue(forAttributeName: "DecodedValue") {
                            keyedContainerInitArgumentSyntax(
                                label: nestedCaseMember.name,
                                containerName: "\(caseMember.name)Container",
                                decodeType: decodedValue.description
                            )
                        } else {
                            keyedContainerInitArgumentSyntax(
                                label: nestedCaseMember.name,
                                containerName: "\(caseMember.name)Container"
                            )
                        }
                    }
                } else {
                    keyedContainerInitArgumentSyntax(label: caseMember.name)
                }
            }
        }
    }

    private static func keyedContainerInitArgumentSyntax(
        label: String,
        containerName: String = "container",
        decodeType: String? = nil
    ) -> LabeledExprSyntax {
        LabeledExprSyntax(
            leadingTrivia: .newline,
            label: "\(raw: label)",
            colon: .colonToken(),
            expression: {
                if let decodeType = $0 {
                    ExprSyntax("\(raw: containerName).decode(\(raw: decodeType), forKey: .\(raw: label)).value()")
                } else {
                    ExprSyntax("\(raw: containerName).decode(for: .\(raw: label))")
                }
            }(decodeType)
        )
    }

    // MARK: Single Value Container

    private static func singleValueContainerBodySyntax() throws -> CodeBlockSyntax {
        try CodeBlockSyntax(
            statementsBuilder: {
                try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
                FunctionCallExprSyntax(callee: ExprSyntax("try self.init")) {
                    LabeledExprSyntax(
                        label: "value",
                        expression: ExprSyntax("container.decode()")
                    )
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
                try VariableDeclSyntax("let container = try decoder.singleValueContainer()")
                try VariableDeclSyntax("let stringValue = try container.decode(String.self)")
                SwitchExprSyntax(
                    subject: ExprSyntax("stringValue"),
                    cases: SwitchCaseListSyntax {
                        for caseMember in mainEnumCasesDecl {
                            singleValueContainerCaseSyntax(
                                label: "\(mainEnumName).\(caseMember.name).rawValue",
                                caseName: caseMember.name
                            )
                        }
                        singleValueContainerDefaultCaseSyntax()
                    }
                )
            }
        )
    }

    private static func singleValueContainerCaseSyntax(label: String, caseName: String) -> SwitchCaseSyntax {
        SwitchCaseSyntax(
            label: .case(
                .init(
                    caseItems: .init(
                        itemsBuilder: {
                            SwitchCaseItemSyntax(
                                pattern: PatternSyntax(stringLiteral: label)
                            )
                        }
                    )
                )
            ),
            statements: CodeBlockItemListSyntax {
                ExprSyntax("self = .\(raw: caseName)")
            }
        )
    }

    private static func singleValueContainerDefaultCaseSyntax() -> SwitchCaseSyntax {
        SwitchCaseSyntax(
            label: .default(.init()),
            statements: CodeBlockItemListSyntax {
                ThrowStmtSyntax(
                    expression: ExprSyntax(
                        """
                        DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Invalid value: \\(stringValue)"
                        )
                        """
                    )
                )
            }
        )
    }
}
