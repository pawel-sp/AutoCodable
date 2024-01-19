import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DecodedValueMacro: PeerMacro {
    public static func expansion(
        of _: SwiftSyntax.AttributeSyntax,
        providingPeersOf _: some SwiftSyntax.DeclSyntaxProtocol,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        []
    }
}
